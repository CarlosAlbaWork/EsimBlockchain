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

    struct PhoneInfo {
        uint16 countryOfPhoneNumber;
        bytes32 encryptedPhoneNumber;
    }

    uint256 private numberOfRegisteredAddresses;
    uint16 private numberOfCountriesSupported;

    mapping(address user => PhoneInfo phoneInfo) s_PhoneNumbers;
    mapping(uint16 countryId => address countryInfoAddress) s_CountryInfoContracts;

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
     * uint16 countryNumber_,
        bool isActive_,
        address factoryContractAddress_,
        uint256 decimals_,
        uint256 feeOnCancel_,
        uint8 feeOnCancelMultiplier_,
        address owner
     */

    function createNewCountryInfo(uint16 countryId_,uint256 decimals_, uint256 feeOnCancel_, uint8 feeOnCancelMultiplier_ ) external onlyOwner {
        if (s_CountryInfoContracts[countryId_] == address(0)) {
            revert CountryInfoFactory__CountryIsRegistered();
        }

        CountryInfo newCountry = new CountryInfo(countryId_, false, address(this), decimals_, feeOnCancel_, feeOnCancelMultiplier_, owner());
        s_CountryInfoContracts[countryId_] = address(newCountry);
        numberOfCountriesSupported++;
    }

    function changePhoneNumberOfAddress(bytes32 encryptedPhoneNumber_, uint16 countryId_) external {
        bytes32 zero;
        if (s_PhoneNumbers[msg.sender].encryptedPhoneNumber == zero) {
            revert CountryInfoFactory__UserNotRegistered();
        }
        s_PhoneNumbers[msg.sender].encryptedPhoneNumber = encryptedPhoneNumber_;
        s_PhoneNumbers[msg.sender].countryOfPhoneNumber = countryId_;
    }

    function buyDataPlan(uint256 startingTimestamp_, uint256 endingTimestamp_, uint16 plan_, uint16 countryId_)
        external
        payable
    {
        bytes32 zero;
        if (s_PhoneNumbers[msg.sender].encryptedPhoneNumber == zero) {
            revert CountryInfoFactory__UserNotRegistered();
        }
        if (s_CountryInfoContracts[countryId_] == address(0)) {
            revert CountryInfoFactory__CountryWithThatIdHasNoSupport();
        }
        CountryInfo countryContract = CountryInfo(s_CountryInfoContracts[countryId_]);
        countryContract.buyDataPlan{value: msg.value}(
            startingTimestamp_, endingTimestamp_, plan_, s_PhoneNumbers[msg.sender].encryptedPhoneNumber
        );
    }

    

    function getNumberOfRegisteredAddresses() external view returns (uint256) {
        return numberOfRegisteredAddresses;
    }

    function getNumberOfCountriesSupported() external view returns (uint16) {
        return numberOfCountriesSupported;
    }

    function getYourPhoneInfo() external view returns (PhoneInfo memory phoneInfo) {
        return s_PhoneNumbers[msg.sender];
    }

    function getPhoneInfoOwnerOnly(address user) external view onlyOwner returns (PhoneInfo memory phoneInfo) {
        return s_PhoneNumbers[user];
    }

    function getCountryInfoAddress(uint16 plan_) external view returns (address phoneInfo) {
        return s_CountryInfoContracts[plan_];
    }
}
