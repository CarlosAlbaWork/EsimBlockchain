// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract CountryInfo is Ownable {
    ///////////////////
    // ERRORS /////////
    ///////////////////

    error CountryInfo__NotEnoughEthSent();
    error CountryInfo__PlanNotAvailable();
    error CountryInfo__SenderMustBeCountryFactory();
    error CountryInfo__NeverBoughtAPlanBefore();
    error CountryInfo__AlreadyInDataPlan();
    error CountryInfo__ContractIsNotActive();
    error CountryInfo__InvalidStartingTimestamp();
    error CountryInfo__InvalidEndingTimestamp();
    error CountryInfo__InvalidPlanId();
    error CountryInfo__TransferFailed();

    ///////////////////
    // EVENTS /////////
    ///////////////////

    event CountryInfo_NewPlanBought(
        bytes32 indexed encryptedPhoneNumber,
        uint256 indexed plan,
        uint256 indexed amountPaid,
        uint256 planPrice,
        uint256 startingTimestamp,
        uint256 endingTimestamp
    );
    event CountryInfo_PlanExtended(
        bytes32 indexed encryptedPhoneNumber, uint256 indexed oldEndingTimestamp, uint256 indexed newEndingTimestamp
    );
    event CountryInfo_PlanUpgraded(
        bytes32 indexed encryptedPhoneNumber, uint16 indexed oldplan, uint16 indexed newplan
    );

    ///////////////////
    // STRUCTS /////////
    ///////////////////

    struct Info {
        uint256 startingTimestamp;
        uint256 endingTimestamp;
        uint16 planSelected;
        uint256 pricePerSecondOfPlan;
        uint256 amountPaid;
        uint256 extraMoneyPaid;
    }

    ///////////////////
    // MODIFIERS /////////
    ///////////////////

    modifier isContractActive() {
        if (!isActive) {
            revert CountryInfo__ContractIsNotActive();
        }
        _;
    }

    ///////////////////
    // CORE VARIABLES /////////
    ///////////////////

    /**
     * countryNumber : Number of the country in our external database
     * isActive : Variable that determines if the contract can be used now
     * s_UserPlans : Stores the Plan information for every PhoneNumber
     * s_DataPlans : Stores the price for every Plan
     * @dev Is it possible to store this info(countrynumber, bool isActive) more gas efficiently in a 32 byte slot?
     */

    uint16 immutable countryNumber;
    bool private isActive;
    address private factoryContractAddress;
    address private transferAddress;
    uint256 immutable decimalsPrecision; //Ex: 1000 = 3 decimals, 100000 = 5 decimals
    uint256 private feeOnCancel; //Ex in constructor you enter 2675 and you want 3 decimals ->  2675 / decimalsPrecision = 2.675%
    uint8 private feeOnCancelMultiplier; //Multiplier used to say the extra fee for cancelling an ongoing plan
    uint256 private feesCollected;
    mapping(bytes32 encryptedPhoneNumber => Info infoOfTimeBought) s_UserPlans;
    /**
     * @dev could be uint8 planSelected(in mapping and Info Struct) if not many plans Available overall
     */
    mapping(uint16 planSelected => uint256 priceOfPlanPerSecond) s_DataPlans;

    constructor(
        uint16 countryNumber_,
        bool isActive_,
        address factoryContractAddress_,
        uint256 decimals_,
        uint256 feeOnCancel_,
        uint8 feeOnCancelMultiplier_
    ) Ownable(msg.sender) {
        countryNumber = countryNumber_;
        factoryContractAddress = factoryContractAddress_;
        decimalsPrecision = decimals_;
        feeOnCancel = feeOnCancel_;
        feeOnCancelMultiplier = feeOnCancelMultiplier_;
        if (isActive) {
            isActive = isActive_;
        }
    }

    function buyDataPlan(
        uint256 startingTimestamp_,
        uint256 endingTimestamp_,
        uint16 plan_,
        bytes32 encryptedPhoneNumber_
    ) external payable isContractActive {
        if (startingTimestamp_ != 0 && startingTimestamp_ < block.timestamp) {
            revert CountryInfo__InvalidStartingTimestamp();
        }

        if (startingTimestamp_ >= endingTimestamp_ || block.timestamp > endingTimestamp_) {
            revert CountryInfo__InvalidEndingTimestamp();
        }
        if (startingTimestamp_ == 0) {
            startingTimestamp_ = block.timestamp;
        }

        if (s_UserPlans[encryptedPhoneNumber_].endingTimestamp > block.timestamp) {
            revert CountryInfo__AlreadyInDataPlan();
        }
        uint256 pricePerSecondOfPlan = s_DataPlans[plan_];

        if (pricePerSecondOfPlan == 0) {
            revert CountryInfo__PlanNotAvailable();
        }

        uint256 priceOfFullPlan = s_DataPlans[plan_] * (endingTimestamp_ - startingTimestamp_);

        uint256 extraMoneyPaidBefore = s_UserPlans[encryptedPhoneNumber_].extraMoneyPaid;

        if (extraMoneyPaidBefore < priceOfFullPlan && msg.value < priceOfFullPlan - extraMoneyPaidBefore) {
            revert CountryInfo__NotEnoughEthSent();
        }

        Info memory info;
        info.amountPaid += msg.value;
        info.endingTimestamp = endingTimestamp_;
        info.planSelected = plan_;
        info.pricePerSecondOfPlan = pricePerSecondOfPlan;
        info.startingTimestamp = startingTimestamp_;

        if (extraMoneyPaidBefore == 0) {
            info.extraMoneyPaid = msg.value - priceOfFullPlan;
        } else {
            if (extraMoneyPaidBefore >= priceOfFullPlan) {
                info.extraMoneyPaid = extraMoneyPaidBefore - priceOfFullPlan + msg.value;
            } else {
                info.extraMoneyPaid = msg.value - (priceOfFullPlan - extraMoneyPaidBefore);
            }
        }

        s_UserPlans[encryptedPhoneNumber_] = info;

        emit CountryInfo_NewPlanBought(
            encryptedPhoneNumber_, plan_, msg.value, pricePerSecondOfPlan, startingTimestamp_, endingTimestamp_
        );
    }

    function extendPlan(bytes32 encryptedPhoneNumber_, uint256 endingTimestamp_) external payable isContractActive {
        Info memory aux = s_UserPlans[encryptedPhoneNumber_];

        if (aux.amountPaid == 0) {
            revert CountryInfo__NeverBoughtAPlanBefore();
        }

        if (aux.endingTimestamp >= endingTimestamp_) {
            revert CountryInfo__InvalidEndingTimestamp();
        }

        uint256 priceOfFullExtension = s_DataPlans[aux.planSelected] * (endingTimestamp_ - aux.endingTimestamp);

        if (aux.extraMoneyPaid < priceOfFullExtension && msg.value < priceOfFullExtension - aux.extraMoneyPaid) {
            revert CountryInfo__NotEnoughEthSent();
        }

        uint256 oldtimestamp = aux.endingTimestamp;
        aux.amountPaid = aux.amountPaid + msg.value;
        aux.endingTimestamp = endingTimestamp_;
        uint256 extraMoneyPaidBefore = aux.extraMoneyPaid;
        if (extraMoneyPaidBefore == 0) {
            aux.extraMoneyPaid = msg.value - priceOfFullExtension;
        } else {
            if (extraMoneyPaidBefore >= priceOfFullExtension) {
                aux.extraMoneyPaid = extraMoneyPaidBefore - priceOfFullExtension + msg.value;
            } else {
                aux.extraMoneyPaid = msg.value - (priceOfFullExtension - extraMoneyPaidBefore);
            }
        }

        s_UserPlans[encryptedPhoneNumber_] = aux;
        emit CountryInfo_PlanExtended(encryptedPhoneNumber_, oldtimestamp, aux.endingTimestamp);
    }

    function upgradePlan(bytes32 encryptedPhoneNumber_, uint16 newPlan_) external payable isContractActive {
        Info memory aux = s_UserPlans[encryptedPhoneNumber_];

        if (msg.sender != factoryContractAddress) {
            revert CountryInfo__SenderMustBeCountryFactory();
        }

        if (aux.amountPaid == 0) {
            revert CountryInfo__NeverBoughtAPlanBefore();
        }

        if (aux.endingTimestamp <= block.timestamp) {
            revert CountryInfo__InvalidEndingTimestamp();
        }

        uint256 pricePerSecondOfNewPlan = s_DataPlans[newPlan_];

        if (pricePerSecondOfNewPlan == 0) {
            revert CountryInfo__InvalidPlanId();
        }
        uint256 priceOfFullUpgrade = pricePerSecondOfNewPlan * (aux.endingTimestamp - block.timestamp);

        if (aux.extraMoneyPaid < priceOfFullUpgrade && msg.value < priceOfFullUpgrade - aux.extraMoneyPaid) {
            revert CountryInfo__NotEnoughEthSent();
        }

        uint256 extraMoneyPaidBefore = aux.extraMoneyPaid;

        if (extraMoneyPaidBefore == 0) {
            aux.extraMoneyPaid = msg.value - priceOfFullUpgrade;
        } else {
            if (extraMoneyPaidBefore >= priceOfFullUpgrade) {
                aux.extraMoneyPaid = extraMoneyPaidBefore - priceOfFullUpgrade + msg.value;
            } else {
                aux.extraMoneyPaid = msg.value - (priceOfFullUpgrade - extraMoneyPaidBefore);
            }
        }

        aux.pricePerSecondOfPlan = pricePerSecondOfNewPlan;

        uint16 oldPlan = aux.planSelected;
        aux.planSelected = newPlan_;

        aux.amountPaid = aux.amountPaid + msg.value;
        s_UserPlans[encryptedPhoneNumber_] = aux;
        emit CountryInfo_PlanUpgraded(encryptedPhoneNumber_, oldPlan, newPlan_);
    }

    function transferFunds() external {
        if (feesCollected != 0) {
            uint256 feesToTransfer = feesCollected;
            feesCollected = 0;
            (bool success,) = transferAddress.call{value: feesToTransfer}("");
            if (!success) {
                revert CountryInfo__TransferFailed();
            }
        }
    }

    function cancelPlan(bytes32 encryptedPhoneNumber_, address user_) external {
        if (msg.sender != factoryContractAddress) {
            revert CountryInfo__SenderMustBeCountryFactory();
        }
        Info memory aux = s_UserPlans[encryptedPhoneNumber_];
        if (aux.endingTimestamp <= block.timestamp) {
            revert CountryInfo__InvalidEndingTimestamp();
        }
        uint256 moneyToCancel = aux.amountPaid;
        uint256 feeUsed = feeOnCancel;
        if (aux.startingTimestamp <= block.timestamp) {
            moneyToCancel = aux.pricePerSecondOfPlan * (aux.endingTimestamp - block.timestamp) + aux.extraMoneyPaid;
            feeUsed = feeOnCancel * feeOnCancelMultiplier;
        }

        uint256 feeCollected = ((moneyToCancel * feeUsed) / (decimalsPrecision * 100));
        uint256 moneyToTransfer = moneyToCancel - feeCollected;
        feesCollected += feeCollected;
        Info memory empty;
        s_UserPlans[encryptedPhoneNumber_] = empty;
        (bool success,) = user_.call{value: moneyToTransfer}("");
        if (!success) {
            revert CountryInfo__TransferFailed();
        }
    }

    //////////////
    ///SETTERS////
    //////////////

    function setIsActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function setFactoryContractAddress(address _factoryContractAddress) external onlyOwner {
        factoryContractAddress = _factoryContractAddress;
    }

    function setFeeOnCancel(uint256 _feeOnCancel) external onlyOwner {
        feeOnCancel = _feeOnCancel;
    }

    function setFeeOnCancelMultiplier(uint8 _feeOnCancelMultiplier) external onlyOwner {
        feeOnCancelMultiplier = _feeOnCancelMultiplier;
    }

    //////////////
    ///GETTERS////
    //////////////

    function getIsActive() external view returns (bool) {
        return isActive;
    }

    function getFactoryContractAddress() external view returns (address) {
        return factoryContractAddress;
    }

    function getDecimalsPrecision() external view returns (uint256) {
        return decimalsPrecision;
    }

    function getFeeOnCancel() external view returns (uint256) {
        return feeOnCancel;
    }

    function getFeeOnCancelMultiplier() external view returns (uint8) {
        return feeOnCancelMultiplier;
    }

    function getDataPlanPrice(uint16 plan_) external view returns (uint256) {
        return s_DataPlans[plan_];
    }

    function getUserPlan(bytes32 encryptedPhoneNumber_) external view returns (Info memory) {
        return s_UserPlans[encryptedPhoneNumber_];
    }
}
