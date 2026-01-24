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

//**
//* @tittle a sample Raffle contract */
//* @author Lovro Posel
//* @this contract is for creating a sample raffle 


//* @dev implements chainlink VRFv2.5

contract Raffle{
    //Errors
    error Raffle__SenderMoreToEnterRaffle();

    uint256 private immutable I_ENTRANCE_FEE;

    constructor(uint256 entranceFee){
        I_ENTRANCE_FEE = entranceFee;
    }

    function enterRaffle() public payable{
       // require(msg.value > I_ENTRANCE_FEE, "Not enough ETH sent!");
      if(msg.value < I_ENTRANCE_FEE){
        revert Raffle__SenderMoreToEnterRaffle();
    }


function pickWinner() public {
    //
}

//** Getter Functions */

function getEntranceFee() external view returns (uint256){
return I_ENTRANCE_FEE;
}
}