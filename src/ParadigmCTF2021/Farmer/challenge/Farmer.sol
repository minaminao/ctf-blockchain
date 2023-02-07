pragma solidity ^0.8.0;

interface IComptroller {
    function claimComp(address holder, address[] calldata cTokens) external;
    function claimableComp() external view returns (uint256);
}

interface ERC20Like {
    function transfer(address dst, uint256 qty) external returns (bool);

    function transferFrom(address src, address dst, uint256 qty) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);
}

interface WETH9 is ERC20Like {
    function deposit() external payable;
}

interface CERC20Like is ERC20Like {
    function mint(uint256 mintAmount) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
}

interface UniRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
}

// Mock contract to not have to deal with Compound's inflation in the challenge
// Assumes it gets funded somehow
contract CompFaucet {
    address owner;
    ERC20Like public constant comp = ERC20Like(0xc00e94Cb662C3520282E6f5717214004A7f26888);

    constructor(address _owner) {
        owner = _owner;
    }

    function claimComp(address, address[] calldata) external {
        comp.transfer(owner, comp.balanceOf(address(this)));
    }

    function claimableComp() public view returns (uint256) {
        return comp.balanceOf(address(this));
    }
}

contract CompDaiFarmer {
    address public owner = msg.sender;
    address public harvester = msg.sender;

    ERC20Like public constant dai = ERC20Like(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    UniRouter public constant router = UniRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    WETH9 public constant WETH = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    CERC20Like public constant CDAI = CERC20Like(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    ERC20Like public constant COMP = ERC20Like(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    IComptroller public comptroller;

    mapping(address => uint256) deposits;

    function peekYield() public view returns (uint256) {
        uint256 claimableAmount = IComptroller(comptroller).claimableComp();

        address[] memory path = new address[](3);
        path[0] = address(COMP);
        path[1] = address(WETH);
        path[2] = address(dai);

        uint256[] memory amounts = router.getAmountsOut(claimableAmount, path);
        return amounts[2];
    }

    function deposit(uint256 amount) public {
        require(dai.transferFrom(msg.sender, address(this), amount));
        deposits[msg.sender] += amount;
    }

    function withdraw(uint256 amount) public {
        deposits[msg.sender] -= amount;
        require(dai.transfer(msg.sender, amount));
    }

    // mints all possible dai to cdai
    function mint() public {
        uint256 daiBalance = dai.balanceOf(address(this));
        dai.approve(address(CDAI), daiBalance);
        CDAI.mint(daiBalance);
    }

    function redeemUnderlying(uint256 amount) public {
        require(msg.sender == owner || amount <= deposits[msg.sender], "cannot redeem more than your balance");
        CDAI.redeemUnderlying(amount);
    }

    // claims a bunch of comp
    function claim() public {
        address[] memory ctokens = new address[](1);
        ctokens[0] = address(CDAI);
        IComptroller(comptroller).claimComp(address(this), ctokens);
    }

    // recycles the comp back to dai
    function recycle() public returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = address(COMP);
        path[1] = address(WETH);
        path[2] = address(dai);

        uint256 bal = COMP.balanceOf(address(this));
        COMP.approve(address(router), bal);

        uint256[] memory amts = router.swapExactTokensForTokens(bal, 0, path, address(this), block.timestamp + 1800);

        return amts[2];
    }

    function claimAndRecycle() public {
        require(msg.sender == harvester, "err/only harvester");
        claim();
        recycle();
    }

    function changeHarvester(address newHarvester) public {
        require(msg.sender == owner);
        harvester = newHarvester;
    }

    function setComp(address _comptroller) public {
        require(msg.sender == owner);
        comptroller = IComptroller(_comptroller);
    }
}
