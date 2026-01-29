//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

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
}