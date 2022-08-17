pragma solidity ^0.8.0;

interface ERC20Like {
    function transfer(address dst, uint256 qty) external returns (bool);
    function transferFrom(address src, address dst, uint256 qty) external returns (bool);
    function approve(address dst, uint256 qty) external returns (bool);
    function allowance(address src, address dst) external returns (uint256);
    function balanceOf(address who) external view returns (uint256);
}

contract Bouncer {
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant entryFee = 1 ether;

    address owner;

    constructor() payable {
        owner = msg.sender;
    }

    mapping(address => address) public delegates;
    mapping(address => mapping(address => uint256)) public tokens;

    struct Entry {
        uint256 amount;
        uint256 timestamp;
        ERC20Like token;
    }

    mapping(address => Entry[]) entries;

    // declare intent to enter
    function enter(address token, uint256 amount) public payable {
        require(msg.value == entryFee, "err fee not paid");
        entries[msg.sender].push(Entry({amount: amount, token: ERC20Like(token), timestamp: block.timestamp}));
    }

    function convertMany(address who, uint256[] memory ids) public payable {
        for (uint256 i = 0; i < ids.length; i++) {
            convert(who, ids[i]);
        }
    }

    // use the returned number to gatekeep
    function contributions(address who, address[] memory coins) public view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](coins.length);
        for (uint256 i = 0; i < coins.length; i++) {
            res[i] = tokens[who][coins[i]];
        }
        return res;
    }

    // convert your erc20s to tokens
    function convert(address who, uint256 id) public payable {
        Entry memory entry = entries[who][id];
        require(block.timestamp != entry.timestamp, "err/wait after entering");
        if (address(entry.token) != ETH) {
            require(entry.token.allowance(who, address(this)) == type(uint256).max, "err/must give full approval");
        }
        require(msg.sender == who || msg.sender == delegates[who]);
        proofOfOwnership(entry.token, who, entry.amount);
        tokens[who][address(entry.token)] += entry.amount;
    }

    // redeem your tokens for their underlying erc20
    function redeem(ERC20Like token, uint256 amount) public {
        tokens[msg.sender][address(token)] -= amount;
        payout(token, msg.sender, amount);
    }

    function payout(ERC20Like token, address to, uint256 amount) private {
        if (address(token) == ETH) {
            payable(to).transfer(amount);
        } else {
            require(token.transfer(to, amount), "err/not enough tokens");
        }
    }

    function proofOfOwnership(ERC20Like token, address from, uint256 amount) public payable {
        if (address(token) == ETH) {
            require(msg.value == amount, "err/not enough tokens");
        } else {
            require(token.transferFrom(from, address(this), amount), "err/not enough tokens");
        }
    }

    function addDelegate(address from, address to) public {
        require(msg.sender == owner || msg.sender == from);
        delegates[from] = to;
    }

    function removeDelegate(address from) public {
        require(msg.sender == owner || msg.sender == from);
        delete delegates[from];
    }

    // get all the fees given during registration
    function claimFees() public {
        require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
    }

    // owner can trigger arbitrary calls
    function hatch(address target, bytes memory data) public {
        require(msg.sender == owner);
        (bool ok, bytes memory res) = target.delegatecall(data);
        require(ok, string(res));
    }
}

contract Party {
    Bouncer bouncer;

    constructor(Bouncer _bouncer) {
        bouncer = _bouncer;
    }

    function isAllowed(address who) public view returns (bool) {
        address[] memory res = new address[](2);
        res[0] = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        res[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        uint256[] memory contribs = bouncer.contributions(who, res);
        uint256 sum;
        for (uint256 i = 0; i < contribs.length; i++) {
            sum += contribs[i];
        }
        return sum > 1000 * 1 ether;
    }
}
