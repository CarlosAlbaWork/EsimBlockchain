// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {CountryInfo} from "./CountryInfo.sol";

contract CountryInfoFactory is Ownable {
    ///////////////////
    // ERRORS /////////
    ///////////////////

    error CountryInfoFactory__UserNotRegistered();
    error CountryInfoFactory__CountryWithThatIdHasNoSupport();
    error CountryInfoFactory__CountryIsRegistered();
    error CountryInfoFactory__UserIsRegistered();

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Struct that contains the information of the phones
     * countryOfPhoneNumber : ID of the country where the phone number is from
     */

    struct PhoneInfo {
        uint16 countryOfPhoneNumber;
        bytes32 encryptedPhoneNumber;
    }

    /**
     * @dev Variables:
     * numberOfRegisteredAddresses : Quantity of users
     * numberOfCountriesSupported : Quantity of countries which have a CountryInfo Contract associated
     * s_PhoneNumbers : Information of the phones releated to the addresses
     * s_CountryInfoContracts : Addresses of the CountryInfo Contracts 
     */

    uint256 private numberOfRegisteredAddresses;
    uint16 private numberOfCountriesSupported;

    mapping(address user => PhoneInfo phoneInfo) s_PhoneNumbers;
    mapping(uint16 countryId => address countryInfoAddress) s_CountryInfoContracts;

    /**
     * @dev Function that saves the information of the Phone related to an address
     * @param phoneNumberCountry_ : country where the phone is 
     * @param encryptedPhoneNumber_ : Phone number that will be linked to that address
     */

    function registerAccount(uint16 phoneNumberCountry_, bytes32 encryptedPhoneNumber_) external {
        bytes32 zero;
        if (s_PhoneNumbers[msg.sender].encryptedPhoneNumber != zero) {
            revert CountryInfoFactory__UserIsRegistered();
        }
        PhoneInfo memory aux;
        aux.countryOfPhoneNumber = phoneNumberCountry_;
        aux.encryptedPhoneNumber = encryptedPhoneNumber_;
        s_PhoneNumbers[msg.sender] = aux;
        numberOfRegisteredAddresses++;
    }

    /**
     * @dev Function that creates new CountryInfo Contracts
     * @param countryId_ : Id of the new country 
     * @param decimals_  : Decimals that will be used 
     * @param feeOnCancel_ : Fee that will be deducted if a plan is cancelled
     * @param feeOnCancelMultiplier_ : Multiplier in case the plan is cancelled midway
     */

    function createNewCountryInfo(
        uint16 countryId_,
        uint256 decimals_,
        uint256 feeOnCancel_,
        uint8 feeOnCancelMultiplier_
    ) external onlyOwner {
        if (s_CountryInfoContracts[countryId_] != address(0)) {
            revert CountryInfoFactory__CountryIsRegistered();
        }

        CountryInfo newCountry =
            new CountryInfo(countryId_, false, address(this), decimals_, feeOnCancel_, feeOnCancelMultiplier_, owner());
        s_CountryInfoContracts[countryId_] = address(newCountry);
        numberOfCountriesSupported++;
    }

    /**
     * @dev Change the phone Number of an address
     * @param countryId_ : country where the phone is 
     * @param encryptedPhoneNumber_ : Phone number that will be linked to that address
     */

    function changePhoneNumberOfAddress(bytes32 encryptedPhoneNumber_, uint16 countryId_) external {
        bytes32 zero;
        if (s_PhoneNumbers[msg.sender].encryptedPhoneNumber == zero) {
            revert CountryInfoFactory__UserNotRegistered();
        }
        s_PhoneNumbers[msg.sender].encryptedPhoneNumber = encryptedPhoneNumber_;
        s_PhoneNumbers[msg.sender].countryOfPhoneNumber = countryId_;
    }

    function getNumberOfRegisteredAddresses() external view returns (uint256) {
        return numberOfRegisteredAddresses;
    }

    function getNumberOfCountriesSupported() external view returns (uint16) {
        return numberOfCountriesSupported;
    }

    function getYourPhoneInfo() external view returns (uint16, bytes32) {
        return (s_PhoneNumbers[msg.sender].countryOfPhoneNumber, s_PhoneNumbers[msg.sender].encryptedPhoneNumber);
    }

    function getPhoneInfoOwnerOnly(address user) external view onlyOwner returns (PhoneInfo memory phoneInfo) {
        return s_PhoneNumbers[user];
    }

    function getCountryInfoAddress(uint16 countryID_) external view returns (address phoneInfo) {
        return s_CountryInfoContracts[countryID_];
    }
}
