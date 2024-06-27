// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {CountryInfoFactory} from "../src/CountryInfoFactory.sol";


contract DeployCountryInfoFactory is Script {
    function run() public returns (CountryInfoFactory) {
        vm.startBroadcast();
        CountryInfoFactory countryInfoFactory = new CountryInfoFactory();
        vm.stopBroadcast();
        return (countryInfoFactory);
    }
}