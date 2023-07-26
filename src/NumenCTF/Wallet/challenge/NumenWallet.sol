// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract NC is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    address public admin;

    constructor() {
        _mint(msg.sender, 100 * 10 ** 18);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        if (tx.origin == admin) {
            require(msg.sender.code.length > 0);
            _allowances[spender][tx.origin] = amount;
            return;
        }
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}

struct Holder {
    address user;
    string name;
    bool approve;
    bytes reason;
}

struct Signature {
    uint8 v;
    bytes32[2] rs;
}

// sign by owner
struct SignedByowner {
    Holder holder;
    Signature signature;
}

contract Wallet {
    address[] public owners;
    address public immutable token;
    Verifier public immutable verifier;
    mapping(address => uint256) public contribution;
    address[] public contributors;

    constructor() {
        token = address(new NC());
        verifier = new Verifier();
        initWallet();
    }

    function initWallet() private {
        owners.push(address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4));
        owners.push(address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2));
        owners.push(address(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db));
        owners.push(address(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB));
        owners.push(address(0x617F2E2fD72FD9D5503197092aC168c91465E7f2));
    }

    function deposit(uint256 amount) public {
        require(amount > 0, "Deposit value of 0 is not allowed");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        if (contribution[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        contribution[msg.sender] += amount;
    }

    function transferWithSign(address to, uint256 amount, SignedByowner[] calldata signs) external {
        require(address(0) != to, "Please fill in the correct address");
        require(amount > 0, "amount must be greater than 0");
        uint256 len = signs.length;
        require(len > (owners.length / 2), "Not enough signatures");
        Holder memory holder;
        uint256 numOfApprove;
        for (uint256 i; i < len; i++) {
            holder = signs[i].holder;
            if (holder.approve) {
                // Prevent zero address
                require(checkSinger(holder.user), "Signer is not wallet owner");
                verifier.verify(to, amount, signs[i]);
            } else {
                continue;
            }
            numOfApprove++;
        }
        require(numOfApprove > owners.length / 2, "not enough confirmation");
        IERC20(token).approve(to, amount);
        IERC20(token).transfer(to, amount);
    }

    function checkSinger(address _addr) public view returns (bool res) {
        for (uint256 i; i < owners.length; i++) {
            if (owners[i] == _addr) {
                res = true;
            }
        }
    }

    function isSolved() public view returns (bool) {
        return IERC20(token).balanceOf(address(this)) == 0;
    }
}

contract Verifier {
    function verify(address to, uint256 amount, SignedByowner calldata scoupon) public pure {
        Holder memory holder = scoupon.holder;
        Signature memory sig = scoupon.signature;
        bytes memory serialized = abi.encode(to, amount, holder.approve, holder.reason);

        require(
            ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", serialized)), sig.v, sig.rs[0], sig.rs[1]
            ) == holder.user,
            "Invalid signature"
        );
    }
}
