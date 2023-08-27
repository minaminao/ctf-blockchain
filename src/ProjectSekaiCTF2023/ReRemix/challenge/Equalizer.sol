// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

library LibMath {
    function abs(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x - y : y - x;
    }
}

// ref: https://solidity-by-example.org/defi/stable-swap-amm/
contract Equalizer is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 private constant N = 3;
    uint256 private constant A = 1000 * (N ** (N - 1));

    address[N] public bands; // frequency bands
    uint256[N] public gains;

    uint256 private constant DECIMALS = 18;
    uint256 public totalVolumeGain;
    mapping(address => uint256) public volumeGainOf;

    error NotConverge(string);
    error Invalid(string);

    constructor(address[N] memory _bands) {
        bands = _bands;
    }

    function _mint(address to, uint256 gain) internal {
        volumeGainOf[to] += gain;
        totalVolumeGain += gain;
    }

    function _burn(address from, uint256 gain) internal {
        volumeGainOf[from] -= gain;
        totalVolumeGain -= gain;
    }

    function _getD(uint256[N] memory xp) internal pure returns (uint256) {
        uint256 a = A * N;

        uint256 s;
        for (uint256 i; i < N; ++i) {
            s += xp[i];
        }

        uint256 d = s;
        uint256 d_prev;
        for (uint256 i; i < 255; ++i) {
            uint256 p = d;
            for (uint256 j; j < N; ++j) {
                p = (p * d) / (N * xp[j]);
            }
            d_prev = d;
            d = ((a * s + N * p) * d) / ((a - 1) * d + (N + 1) * p);

            if (LibMath.abs(d, d_prev) <= 1) {
                return d;
            }
        }
        revert NotConverge("D");
    }

    function _getY(uint256 i, uint256 j, uint256 x, uint256[N] memory xp) internal pure returns (uint256) {
        uint256 a = A * N;
        uint256 d = _getD(xp);
        uint256 s;
        uint256 c = d;

        uint256 _x;
        for (uint256 k; k < N; ++k) {
            if (k == i) {
                _x = x;
            } else if (k == j) {
                continue;
            } else {
                _x = xp[k];
            }

            s += _x;
            c = (c * d) / (N * _x);
        }
        c = (c * d) / (N * a);
        uint256 b = s + d / a;

        uint256 y_prev;
        uint256 y = d;
        for (uint256 _i; _i < 255; ++_i) {
            y_prev = y;
            y = (y * y + c) / (2 * y + b - d);
            if (LibMath.abs(y, y_prev) <= 1) {
                return y;
            }
        }
        revert NotConverge("Y");
    }

    function getGlobalInfo() external view returns (uint256) {
        uint256 d = _getD(gains);
        uint256 _totalVolumeGain = totalVolumeGain;
        if (_totalVolumeGain > 0) {
            return (d * 10 ** DECIMALS) / _totalVolumeGain;
        }
        return 0;
    }

    /**
     * @param i index of the band to boost
     * @param j index of the band to cut
     * @param dx determines the magnitude of the boost
     * @return dy determines the magnitude of the cut
     */
    function equalize(uint256 i, uint256 j, uint256 dx) external payable nonReentrant returns (uint256 dy) {
        if (i == j) {
            revert Invalid("index");
        }
        if (dx == 0) {
            revert Invalid("dx");
        }

        if (i == 0) {
            if (msg.value != dx) {
                revert Invalid("value");
            }
        } else {
            if (msg.value != 0) {
                revert Invalid("value");
            }
            IERC20(bands[i]).safeTransferFrom(msg.sender, address(this), dx);
        }

        uint256[N] memory xp = gains;
        uint256 x = xp[i] + dx;

        uint256 y0 = xp[j];
        uint256 y1 = _getY(i, j, x, xp);
        dy = y0 - y1 - 1;

        gains[i] += dx;
        gains[j] -= dy;

        if (j == 0) {
            payable(msg.sender).sendValue(dy);
        } else {
            IERC20(bands[j]).safeTransfer(msg.sender, dy);
        }
    }

    function increaseVolume(uint256[N] calldata amounts) external payable nonReentrant returns (uint256 variation) {
        uint256 _totalVolumeGain = totalVolumeGain;
        uint256 d0;
        uint256[N] memory old_xs = gains;
        if (_totalVolumeGain > 0) {
            d0 = _getD(old_xs);
        }

        uint256[N] memory new_xs;
        for (uint256 i; i < N; ++i) {
            uint256 amount = amounts[i];
            if (amount > 0) {
                if (i == 0) {
                    require(msg.value == amount);
                } else {
                    IERC20(bands[i]).safeTransferFrom(msg.sender, address(this), amount);
                }
                new_xs[i] = old_xs[i] + amount;
            } else {
                new_xs[i] = old_xs[i];
            }
        }

        uint256 d1 = _getD(new_xs);
        if (d1 <= d0) {
            revert Invalid("not increase");
        }

        // update
        for (uint256 i; i < N; ++i) {
            gains[i] += amounts[i];
        }

        if (_totalVolumeGain > 0) {
            variation = ((d1 - d0) * _totalVolumeGain) / d0;
        } else {
            variation = d1;
        }
        _mint(msg.sender, variation);
    }

    function decreaseVolume(uint256 variation) external nonReentrant returns (uint256[N] memory amounts) {
        if (variation == 0) {
            revert Invalid("variation");
        }
        uint256 _totalVolumeGain = totalVolumeGain;

        for (uint256 i; i < N; ++i) {
            uint256 amount = (variation * gains[i]) / _totalVolumeGain;
            gains[i] -= amount;
            amounts[i] = amount;

            if (i == 0) {
                payable(msg.sender).sendValue(amount);
            } else {
                IERC20(bands[i]).safeTransfer(msg.sender, amount);
            }
        }

        _burn(msg.sender, variation);
    }
}
