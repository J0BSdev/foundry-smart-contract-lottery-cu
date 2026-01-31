//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription,FundSubscription,AddConsumer } from "./Interactions.s.sol";


 contract DeployRaffle is Script {
    function run() public{}

        function deployContract() public returns (Raffle raffle,HelperConfig helperConfig){
      helperConfig = new HelperConfig();
    //local -> deploy mocks ,get local config
    //sepolia -> get sepolia config
      HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();

      if(networkConfig.subscriptionId == 0){
        //create a subscription
        CreateSubscription createsubcription = new CreateSubscription();
       (networkConfig.subscriptionId,networkConfig.vrfCoordinator) =
        createsubcription.createSubscription(networkConfig.vrfCoordinator,networkConfig.account);

        //fund it
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(networkConfig.vrfCoordinator,networkConfig.subscriptionId,networkConfig.link,networkConfig.account);


    //deploy raffle
    vm.startBroadcast(networkConfig.account);
    raffle = new Raffle(
        networkConfig.entranceFee,
        networkConfig.interval,
        networkConfig.vrfCoordinator,
        networkConfig.gasLane,
        networkConfig.subscriptionId,
        networkConfig.callbackGasLimit
    );



vm.stopBroadcast();

AddConsumer addConsumer = new AddConsumer();
//dont need to boradcast here because we are already in the broadcast block
addConsumer.addConsumer(address(raffle),networkConfig.vrfCoordinator,networkConfig.subscriptionId,networkConfig.account);



return (raffle, helperConfig);

     }
 }
 }