// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe){
        // this gets simulated
        HelperConfig helperConfig = new HelperConfig();

        // needs parentheses because it is a struct
        (address ethUsdPriceFeed) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(); 
        // we can create a mock address for our own local chains for the purposes of testing
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}