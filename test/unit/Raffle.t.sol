//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test{
Raffle public raffle;
HelperConfig public helperConfig;

uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;

address public PLAYER = makeAddr("player");
uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;


 event RaffleEntered(address indexed player);
event WinnerPicked(address indexed winner);



    function setUp() external{
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.deployContract();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();
        entranceFee = networkConfig.entranceFee;
        interval = networkConfig.interval;
        vrfCoordinator = networkConfig.vrfCoordinator;
        gasLane = networkConfig.gasLane;
        subscriptionId = networkConfig.subscriptionId;
        callbackGasLimit = networkConfig.callbackGasLimit;
        link = networkConfig.link;


        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    
    }
function testRaffleInitializesInOpenState() public view {
    assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
}

function testRaffleRevertsWhenYouDontPayEnough() public{
    //Arrange
    vm.prank(PLAYER);
    //Act/assertt
    vm.expectRevert(Raffle.Raffle__SendMoretoEnterRaffle.selector);
    raffle.enterRaffle();
    //Assert

}
function testRaffleRevertsWhenYouPayLessThanTheEntranceFee() public{
    //Arrange
    vm.prank(PLAYER);
    //Act/assert
   address playerRecorded = raffle.getPlayer(0);
   assert(playerRecorded == PLAYER);
    //Assert
}






function testRaffleEmitsEventOnEntrance() public{
//Arrange
vm.prank(PLAYER);
//act
vm.expectEmit(true, false, false, false, address(raffle));
emit RaffleEntered(PLAYER);
raffle.enterRaffle{value: entranceFee}();
//assert
}


function testDontAllowPlayerToEnterWhileRaffleIsCalculating() public{
    //Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    raffle.performUpkeep("");

    //act/assert
vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
vm.prank(PLAYER);
raffle.enterRaffle{value: entranceFee}();
}



function testCheckUpkeepReturnsFalseIfItHasNoBalance() public{
//Arrange
vm.warp(block.timestamp + interval + 1);
vm.roll(block.number + 1);


//act
(bool upkeepNeeded, ) = raffle.checkUpkeep("");

//assert
assert(!upkeepNeeded);


}
function testCheckUpkeepReturnsFalseIfRaffleIsNotOpen() public{

//Arrange
vm.warp(block.timestamp + interval + 1);
vm.roll(block.number + 1);
raffle.performUpkeep("");
raffle.enterRaffle{value: entranceFee}();

//act
(bool upkeepNeeded, ) = raffle.checkUpkeep("");
//assert
assert(!upkeepNeeded);



}
//Challenge
       //testCheckUpKeepReturnsFalseIfEnoughTimeHasPassed
       //testCheckUpKeepReturnsTrueWhenParametersAreGood


function testPerformUpkeepCanOnlyRunIfUpkeepIsTrue() public{
    //Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);

    //act
    raffle.performUpkeep("");
    //assert
}

function testPerformUpkeepRevertsIfChecksUpeekpIsFalse() public{
    //Arrange
   uint256 currentBalance = 0;
   uint256 numPlayer = 0;
   Raffle.RaffleState rState = raffle.getRaffleState();

   vm.prank(PLAYER);
   raffle.enterRaffle{value: entranceFee}();
   currentBalance = currentBalance + entranceFee;
   numPlayer = 1 ;

   
//acts/asserts
vm.expectRevert(
    abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector,
    currentBalance,numPlayer,rState));
raffle.performUpkeep("");

}


modifier raffleEntered(){
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    _;
}

function testPerformUpkeepUpadtesRaffleStateAndEmitsRequestId() public raffleEntered(){
    //Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    //act
    vm.recordLogs();
    raffle.performUpkeep("");
    Vm.Log[] memory entries = vm.getRecordedLogs();
    bytes32 requestId = entries[1].topics[1];
//Arange
Raffle.RaffleState raffleState =raffle.getRaffleState();
assert(uint256(requestId) > 0);
assert(uint256(raffleState) == 1);
}



function testFullfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public raffleEntered(){
  //Arrange
  vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
  VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address (raffle));

    }



function testFullfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEntered(){
    //Arrange
    uint256 additionalEntrants = 3; //total 4
    uint256 startindIndex = 1;
    address expectedWinner = address(1);


    for(uint256 i = startindIndex; i < startindIndex + additionalEntrants; i++){
        address newPlayer = address(uint160(i)); // address(1), address(2), address(3)
        hoax(newPlayer , 1 ether);
        raffle.enterRaffle{value: entranceFee}();

    }

uint256 startingTimeStamp = raffle.getLastTimeStamp();
uint256 winnerStartingBalance = expectedWinner.balance;


vm.recordLogs();
    raffle.performUpkeep("");
    Vm.Log[] memory entries = vm.getRecordedLogs();
    bytes32 requestId = entries[1].topics[1];
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address (raffle));

    //assert
    address recentWinner = raffle.getRecentWinner();
    Raffle.RaffleState raffleState = raffle.getRaffleState();
    uint256 winnerBalance = recentWinner.balance;
    uint256 endingTimeStamp = raffle.getLastTimeStamp();
    uint256 prize = entranceFee * (additionalEntrants + 1);

    assert (recentWinner == expectedWinner);
    assert(uint256(raffleState) == 0);
    assert(winnerBalance == winnerStartingBalance + prize);
    assert(endingTimeStamp > startingTimeStamp);

}
    }










    

