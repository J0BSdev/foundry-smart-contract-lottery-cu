//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script,console} from "forge-std/Script.sol";
import {HelperConfig,CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";


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
contract FundSubscription is Script {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
    address subscriptionId = helperConfig.getConfig().subscriptionId;
     uint256 subId = helperConfig.getConfig().subscriptionId;
     address vrfCoordinator = helperConfig.getConfig().vrfCoordinator; 
     address link = helperConfig.getConfig().link;
     fundSubscription(vrfCoordinator,subId,link);
}

function fundSubscription(address vrfCoordinator,uint256 subscriptionId,address link) public{
    console.log("Funding subscription:", subscriptionId);
    console.log("Using vrfCoordinator at:", vrfCoordinator);
    console.log("On chainId:", block.chainid);


if (block.chainid == LOCAL_CHAIN_ID){
    vm.startBroadcast();
    VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId,
    FUND_AMOUNT);
    vm.stopBroadcast();

}else{
    vm.startBroadcast();
}LinkToken(link).transferAndCall(vrfCoordinator , FUND_AMOUNT, (abi.encode(subscriptionId)));
vm.stopBroadcast();
}

        function run() public{
            fundSubscriptionUsingConfig();
} 

}