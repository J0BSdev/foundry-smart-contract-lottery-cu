//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants{
/*VRF Mock values */
uint96 public MOCK_BASE_FEE = 0.25 ether;
uint96 public MOCK_GAS_PRICE = 1e9; //1 gwei
//LINK / ETH price
int256 public MOCK_WEI_PER_UINT_LINK = 4e15;

    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;


}

contract HelperConfig is CodeConstants, Script {
error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
    }

NetworkConfig public activeNetworkConfig;

mapping (uint256 => NetworkConfig) public networkConfig;

constructor() {

networkConfig[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();


}

function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
    if (networkConfig[chainId].vrfCoordinator != address(0)) {
        return networkConfig[chainId];
    } else if (block.chainid == LOCAL_CHAIN_ID) {
           return getOrCreateAnvilConfig();
    //getOrCreateLocalConfig();
    } else {
        revert HelperConfig__InvalidChainId();
    }
}

function getConfig() public returns (NetworkConfig memory) {
    return getConfigByChainId(block.chainid);
}

function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
    return NetworkConfig({
            entranceFee: 0.01 ether, //1e16
            interval: 30, //30 seconds
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x474eae0326401e7ec14af5ebd6d6fee8f89f9bed30ad9e36d9be6093d974f4a8,
            callbackGasLimit: 500000, //500000 gas
            subscriptionId: 0,

            link: 0x79D3D58aCE80aF49453e7c32E1B2018AcaE13E3E
        });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory localNetworkConfig) {
        // Check to see if we set a config for this chain
        if (networkConfig[LOCAL_CHAIN_ID].vrfCoordinator != address(0)) {
            return networkConfig[LOCAL_CHAIN_ID];
        }


  // Deploy mocks and such      
vm.startBroadcast();
VRFCoordinatorV2_5Mock vrfCoordinatorMock = 
    new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE, MOCK_WEI_PER_UINT_LINK);  
vm.stopBroadcast();

localNetworkConfig = NetworkConfig({
    entranceFee: 0.01 ether, //1e16
    interval: 30, //30 seconds
    vrfCoordinator: address(vrfCoordinatorMock),
     //doesnt matter for mocks
    gasLane: 0x474eae0326401e7ec14af5ebd6d6fee8f89f9bed30ad9e36d9be6093d974f4a8,
    callbackGasLimit: 500000, //500000 gas
    subscriptionId: 0,
    link: 0x79D3D58aCE80aF49453e7c32E1B2018AcaE13E3E
}); 

return localNetworkConfig;

    }
}

   