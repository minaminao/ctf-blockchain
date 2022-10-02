// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./chainlink/interfaces/LinkTokenInterface.sol";
import "./chainlink/interfaces/VRFCoordinatorV2Interface.sol";
import "./chainlink/VRFConsumerBaseV2.sol";

contract RhythmGame is VRFConsumerBaseV2 {
    // Goerli testnet configurations
    address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    address linkTokenContract = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    uint64 public subscriptionId;
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    uint256 public allPerfect;
    address player;
    uint256 touchSeq;

    uint256 bonusDrink = 1;
    uint256 bonusEnergy;

    constructor() payable VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(linkTokenContract);
        subscriptionId = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(subscriptionId, address(this));
    }

    function isSolved() public view returns (bool) {
        require(allPerfect == 3, "Try harder! You have to achieve ALL PERFECT 3 times :)");
        return true;
    }

    function fillEnergy() public {
        uint256 amount = 5 * 10 ** 18; // 5 LINK

        require(bonusDrink >= 1, "There are no drinks for you to buy X(");
        require(LINKTOKEN.balanceOf(address(this)) >= amount);

        LINKTOKEN.transferAndCall(address(COORDINATOR), LINKTOKEN.balanceOf(address(this)), abi.encode(subscriptionId));
        bonusDrink = 0;
        bonusEnergy = 30;
    }

    function play(uint256 touchseq) public {
        require(bonusEnergy >= 10, "You have ran out of energy :o");

        player = msg.sender;
        touchSeq = touchseq;

        // A random song will be chosen for you -v-
        COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            3, // requestConfirmations
            100000, // callbackGasLimit
            1 // numWords
        );
    }

    function fulfillRandomWords(
        uint256, // requestId
        uint256[] memory randomWords
    ) internal override {
        uint256 songSeq = randomWords[0] % 3;

        bonusEnergy -= 10;

        // receive the bonus! 0v0
        if (touchSeq != songSeq) {
            payable(player).transfer(5 wei);
            return;
        }
        payable(player).transfer(10 wei);
        allPerfect += 1;
    }
}
