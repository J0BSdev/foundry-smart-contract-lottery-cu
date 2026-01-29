//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script,console} from "forge-std/Script.sol";
import {HelperConfig,CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "foundry-devops/DevOpsTools.sol";


contract CreateSubscription is Script, CodeConstants {
function createSubscriptionUsingConfig() public returns (uint256,address){
    HelperConfig helperConfig = new HelperConfig();
     address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
      (uint256 subId,) = createSubscription(vrfCoordinator);
     return (subId, vrfCoordinator);

}

function createSubscription(address vrfCoordinator) public returns (uint256,address) {
    console.log("Creating subscription on chainId:", block.chainid);
    vm.startBroadcast();
    uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
    vm.stopBroadcast();
    console.log("Your subscription ID is:", subId);
    console.log("Please update your subscription ID in the HelperConfig.s.sol file");
    return (subId, vrfCoordinator);
}
    function run() public{
        createSubscriptionUsingConfig();
    }

}
contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
    uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
     address vrfCoordinator = helperConfig.getConfig().vrfCoordinator; 
     address link = helperConfig.getConfig().link;
     fundSubscription(vrfCoordinator,subscriptionId,link);
}

function fundSubscription(address vrfCoordinator,uint256 subscriptionId,address link) public{
    console.log("Funding subscription:", subscriptionId);
    console.log("Using vrfCoordinator at:", vrfCoordinator);
    console.log("On chainId:", block.chainid);


if (block.chainid == SEPOLIA_CHAIN_ID){
    vm.startBroadcast();
    VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId,
    FUND_AMOUNT);
    vm.stopBroadcast();
} else if(block.chainid == LOCAL_CHAIN_ID){
    vm.startBroadcast();
    LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
    vm.stopBroadcast();
}
}
function run() public{
    fundSubscriptionUsingConfig();
}
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subscriptionId);
    }

function addConsumer(address contractToAddtoVrf, address vrfCoordinator, uint256 subscriptionId) public {
    console.log("Adding consumer contract:", contractToAddtoVrf);
    console.log("Using vrfCoordinator at:", vrfCoordinator);
    console.log("On chainId:", block.chainid);
    vm.startBroadcast();
    VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subscriptionId,contractToAddtoVrf);
    vm.stopBroadcast();
    console.log("Consumer contract added successfully");
}

    function run() external{
address mostRecentlyDeployedContract = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployedContract);
    }

       //Challenge
       //testCheckUpKeepReturnsFalseIfEnoughTimeHasPassed
       //testCheckUpKeepReturnsTrueWhenParametersAreGood


       

}