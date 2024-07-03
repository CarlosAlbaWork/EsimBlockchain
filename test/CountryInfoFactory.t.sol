// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {CountryInfoFactory} from "../src/CountryInfoFactory.sol";
import {CountryInfo} from "../src/CountryInfo.sol";
import {DeployCountryInfoFactory} from "../script/DeployCountryInfoFactory.s.sol";

contract TestCountryInfoFactory is Test {
    CountryInfoFactory countryInfoFactory;
    CountryInfo spain;
    CountryInfo korea;
    address user1 = address(1);
    bytes32 user1PhoneNumber = keccak256(abi.encode(633987089));

    address user2 = address(2);
    bytes32 user2PhoneNumber = keccak256(abi.encode(1089078765));
    address user3 = address(3);
    bytes32 user3PhoneNumber = keccak256(abi.encode(78234591755));

    function setUp() public {
        DeployCountryInfoFactory deployer = new DeployCountryInfoFactory();
        (countryInfoFactory) = deployer.run();
        vm.startPrank(countryInfoFactory.owner());
        countryInfoFactory.createNewCountryInfo(34, 1000, 2000, 2);
        countryInfoFactory.createNewCountryInfo(82, 1000, 3000, 2);
        spain = CountryInfo(countryInfoFactory.getCountryInfoAddress(34));
        korea = CountryInfo(countryInfoFactory.getCountryInfoAddress(82));
        vm.stopPrank();
        vm.prank(user1);
        countryInfoFactory.registerAccount(34, user1PhoneNumber);
        vm.prank(user2);
        countryInfoFactory.registerAccount(82, user2PhoneNumber);
        vm.prank(user3);
        countryInfoFactory.registerAccount(82, user3PhoneNumber);
    }

    function testRegisterAccountRevertsUserRegistered() public {
        vm.startPrank(user1);
        vm.expectRevert(CountryInfoFactory.CountryInfoFactory__UserIsRegistered.selector);
        countryInfoFactory.registerAccount(34, user1PhoneNumber);
    }

    function testRegisterAccount() public {
        uint256 numberOfRegisters = countryInfoFactory.getNumberOfRegisteredAddresses();
        assertEq(numberOfRegisters, uint256(3));
        vm.prank(user1);
        (, bytes32 user1Number) = countryInfoFactory.getYourPhoneInfo();
        assertEq(user1Number, user1PhoneNumber);
        vm.prank(user3);
        (, bytes32 user3Number) = countryInfoFactory.getYourPhoneInfo();
        assertEq(user3Number, user3PhoneNumber);
    }

    function testCreateNewCountryInfoRevertsCountryRegistered() public {
        vm.startPrank(countryInfoFactory.owner());
        vm.expectRevert(CountryInfoFactory.CountryInfoFactory__CountryIsRegistered.selector);
        countryInfoFactory.createNewCountryInfo(34, 1000, 2000, 2);
    }

    function testCreateNewCountryInfo() public {
        vm.startPrank(countryInfoFactory.owner());
        uint256 numberOfRegisters = countryInfoFactory.getNumberOfCountriesSupported();
        assertEq(numberOfRegisters, 2);
        assertEq(countryInfoFactory.getCountryInfoAddress(34), address(spain));
    }

    function testChangePhoneNumberOfAddressRevertsIfNotRegistered() public {
        vm.startPrank(address(5));
        vm.expectRevert(CountryInfoFactory.CountryInfoFactory__UserNotRegistered.selector);
        countryInfoFactory.changePhoneNumberOfAddress(user1PhoneNumber, 34);
    }

    function testChangePhoneNumberOfAddress() public {
        vm.startPrank(user1);
        countryInfoFactory.changePhoneNumberOfAddress(user3PhoneNumber, 34);
        (, bytes32 user1Number) = countryInfoFactory.getYourPhoneInfo();
        assertEq(user1Number, user3PhoneNumber);
    }
}
