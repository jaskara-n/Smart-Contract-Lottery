// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/*Custom errors*/
error notEnoughEthSpent();
error lotteryNotOpen();
error upkeepNotNeeded();
error transferFailed();

/**@title A lottery Smart Contract
 * @author Jaskaran Singh
 * @notice Used to create a untamperable decentralised lottery
 * @dev This uses chainlink VRF V2 and Chainlink keepers
 */

contract theLotteryContract is VRFConsumerBaseV2 {
    enum lotteryState {
        open,
        calculating
    }

    /*State variables*/
    uint256 i_entranceFee;
    address payable[] public s_players;
    VRFCoordinatorV2Interface public immutable i_vrfCoordinator;
    bytes32 public i_gasLane;
    uint64 public i_subscriptionId;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public i_callbackGasLimit;
    uint32 public constant NUM_WORDS = 1;
    address public s_recentWinner;

    /*Lottery variables*/
    lotteryState public s_lotteryState;
    uint256 public s_lastTimeStamp;
    uint256 public immutable i_interval;

    /*events*/
    event LotteryEntered(address indexed player);
    event RequestedLotteryWinner(uint256 indexed requestId);
    event winnerPicked(address indexed winner);

    /*Functions*/
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address VRFCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(VRFCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(VRFCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterLottery() external payable {
        if (msg.value < i_entranceFee) {
            revert notEnoughEthSpent();
        }
        if (s_lotteryState != lotteryState.open) {
            revert lotteryNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit LotteryEntered(msg.sender);
    }

    function checkUpKeep(bytes memory) public view returns (bool upkeepNeeded, bytes memory) {
        bool isOpen = lotteryState.open == s_lotteryState;
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata) external {
        (bool upkeepNeeded, ) = checkUpKeep("");
        if (!upkeepNeeded) {
            revert upkeepNotNeeded();
        }
        s_lotteryState = lotteryState.calculating;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedLotteryWinner(requestId);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_players = new address payable[](0);
        s_lotteryState = lotteryState.open;
        s_lastTimeStamp = block.timestamp;
        s_recentWinner = recentWinner;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert transferFailed();
        }
        emit winnerPicked(recentWinner);
    }
}
