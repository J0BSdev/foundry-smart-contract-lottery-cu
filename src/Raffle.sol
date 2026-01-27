// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

/// @title A sample Raffle contract
/// @author Lovro Posel


//* @dev implements chainlink VRFv2.5

contract Raffle is VRFConsumerBaseV2Plus{
    //Errors
    error Raffle__SendMoretoEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);
    //* @dev number of words to request


    enum RaffleState {
        OPEN,//0
        CALCULATING//1
      
    }

     /*state variables*/
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
   bytes32 private immutable i_keyHash;
   uint256 private immutable i_subscriptionId;
   uint32 private immutable i_callbackGasLimit;
   address payable [] private s_players;
  uint256 private s_lastTimeStamp;
  address private s_recentWinner;
   RaffleState private s_raffleState;
   
    //Events
    event RaffleEntered(address indexed player);
event WinnerPicked(address indexed winner);

    constructor(
    uint256 entranceFee,
    uint256 interval,
    address vrfCoordinator,
    bytes32 gasLane,
    uint256 subscriptionId,
    uint32 callbackGasLimit)
VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
       i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit; 
        s_lastTimeStamp = block.timestamp;
         s_raffleState = RaffleState.OPEN; 
}  
    function enterRaffle() external payable {
      //require(msg.value >== i_entranceFee, "Not enough ETH sent");
      //require(msg.value >== i_entranceFee, "SendMoretoEnterRaffle");
       if (msg.value < i_entranceFee){
        revert Raffle__SendMoretoEnterRaffle();
  }

  s_players.push(payable(msg.sender));
  //1. Makes migration easier
  //2. Maker front indexing easier
  emit RaffleEntered(msg.sender);
    }

//When should winner be picked?
//*
 // * @dev This is the function that Chainlink nodes will call to see
 //* if the lottery is ready to be picked a winner
 //*1. The time interval has passed between raffle runs
//*2. The lottery is open
//*3. The contract has ETH(has players)
//*4. Your subscription has LINK

//*@param - ignored
//*@return - upkeepNeeded - true  if its time to run restart the lottery
//*return - ignored

function checkUpkeep(bytes memory /* checkData */)
    public 
    view
    returns (bool upkeepNeeded, bytes memory performData)

{
bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >=i_interval;
bool isOpen = s_raffleState == RaffleState.OPEN;
bool hasPlayers = s_players.length > 0;
bool hasBalance = address(this).balance > 0;
upkeepNeeded = timeHasPassed && isOpen && hasPlayers && hasBalance;
return (upkeepNeeded,"");

}

// 3. Be automaticaly called
function performUpkeep(bytes calldata /* performData */) external {
  //check to see if enough time has passed
  (bool upkeepNeeded, ) = checkUpkeep("");
  if(!upkeepNeeded){
    revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length,uint256(s_raffleState));
  }

  
s_raffleState = RaffleState.CALCULATING;
VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
  keyHash: i_keyHash,
  subId: i_subscriptionId,
  requestConfirmations: REQUEST_CONFIRMATIONS,
  callbackGasLimit: i_callbackGasLimit,
  numWords: NUM_WORDS,
  extraArgs: VRFV2PlusClient._argsToBytes(
   //Set nativePayment to true to pay in ETH instead of LINK
    VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
});

  s_vrfCoordinator.requestRandomWords(request);


}  
   //CEI: Checks, Effects, Interactions     
  function fulfillRandomWords(uint256 /* requestId */, uint256[] calldata randomWords) internal override{
    //checks
    //conditionals

 //effect (internal contract state)
   uint256 indexOfWinner = randomWords[0] % s_players.length;
   address payable recentWinner = s_players[indexOfWinner];
   s_recentWinner = recentWinner;
   s_raffleState = RaffleState.OPEN;
   s_players = new address payable[](0);
   s_lastTimeStamp = block.timestamp;
   emit WinnerPicked(recentWinner);

   //interactions(external contract interactions)
   (bool success, ) = recentWinner.call{value: address(this).balance}("");
   if(!success){
    revert Raffle__TransferFailed();
   }
  
} 

function getRaffleState() public view returns (RaffleState){
  return s_raffleState;

}

function getPlayer(uint256 index) external view returns (address){

  return s_players[index];

}
}