// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {CountryInfoFactory} from "../src/CountryInfoFactory.sol";
import {CountryInfo} from "../src/CountryInfo.sol";
import {DeployCountryInfoFactory} from "../script/DeployCountryInfoFactory.s.sol";

contract TestCountryInfo is Test {
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
        spain.setIsActive(true);
        korea.setIsActive(true);
        uint16[] memory spainPlans = new uint16[](4);
        spainPlans[0] = 1;
        spainPlans[1] = 2;
        spainPlans[2] = 3;
        spainPlans[3] = 4;

        uint256[] memory pricesPerSecondSpain = new uint256[](4);
        pricesPerSecondSpain[0] = 0.000001 ether;
        pricesPerSecondSpain[1] = 10 ether;
        pricesPerSecondSpain[2] = 0.000015 ether;
        pricesPerSecondSpain[3] = 0.03 ether;

        spain.modifyPlans(spainPlans, pricesPerSecondSpain);

        uint16[] memory koreaPlans = new uint16[](4);
        koreaPlans[0] = 1;
        koreaPlans[1] = 2;
        koreaPlans[2] = 3;
        koreaPlans[3] = 7;

        uint256[] memory pricesPerSecondKorea = new uint256[](4);
        pricesPerSecondKorea[0] = 3;
        pricesPerSecondKorea[1] = 0.00043534 ether;
        pricesPerSecondKorea[2] = 676 ether;
        pricesPerSecondKorea[3] = 23452345;

        korea.modifyPlans(koreaPlans, pricesPerSecondKorea);
        vm.deal(user1, 50 ether);
        vm.deal(user2, 50 ether);
        vm.stopPrank();
    }

    function testModifyPlansRevertsDiffLength() public {
        uint16[] memory aux1 = new uint16[](4);
        aux1[0] = 1;
        aux1[1] = 2;
        aux1[2] = 3;
        aux1[3] = 7;

        uint256[] memory aux2 = new uint256[](3);
        aux2[0] = 3;
        aux2[1] = 43534;
        aux2[2] = 676;

        vm.startPrank(countryInfoFactory.owner());
        vm.expectRevert(CountryInfo.CountryInfo__LengthOfArraysDiffer.selector);
        korea.modifyPlans(aux1, aux2);
        vm.stopPrank();
    }

    function testModifyPlans() public view {
        assertEq(korea.getDataPlanPrice(7), 23452345);
        assertEq(spain.getDataPlanPrice(1), 0.000001 ether);
    }

    //////////////////////////////
    ///buyDataPlan////////////////
    //////////////////////////////

    function testBuyDataPlanRevertsIfWrongStartingtimestamp() public {
        vm.warp(block.timestamp + 5);
        uint256 oldTimestamp = block.timestamp;
        vm.warp(block.timestamp + 63427);
        vm.startPrank(user1);
        vm.expectRevert(CountryInfo.CountryInfo__InvalidStartingTimestamp.selector);
        spain.buyDataPlan{value: 45 ether}(oldTimestamp, block.timestamp + 56, 1, user1PhoneNumber);
    }

    function testBuyDataPlanRevertsIfWrongEndingtimestamp() public {
        vm.warp(block.timestamp + 5);
        vm.warp(block.timestamp + 63427);
        vm.startPrank(user1);
        vm.expectRevert(CountryInfo.CountryInfo__InvalidEndingTimestamp.selector);
        spain.buyDataPlan{value: 45 ether}(block.timestamp + 56, block.timestamp + 34, 1, user1PhoneNumber);
    }

    function testBuyDataPlanRevertsIfWrongEndingtimestamp2() public {
        vm.warp(block.timestamp + 5);
        uint256 oldTimestamp = block.timestamp;
        vm.warp(block.timestamp + 63427);
        vm.startPrank(user1);
        vm.expectRevert(CountryInfo.CountryInfo__InvalidEndingTimestamp.selector);
        spain.buyDataPlan{value: 45 ether}(0, oldTimestamp, 1, user1PhoneNumber);
    }

    function testBuyDataPlanRevertsIfPlanNotAvailable() public {
        vm.startPrank(user1);
        vm.expectRevert(CountryInfo.CountryInfo__PlanNotAvailable.selector);
        spain.buyDataPlan{value: 45 ether}(0, block.timestamp + 1000, 50, user1PhoneNumber);
    }

    function testBuyDataPlanRevertsIfAlreadyInDataPlan() public {
        vm.startPrank(user1);
        spain.buyDataPlan{value: 45 ether}(0, block.timestamp + 1000, 1, user1PhoneNumber);
        vm.expectRevert(CountryInfo.CountryInfo__AlreadyInDataPlan.selector);
        spain.buyDataPlan{value: 5 ether}(0, block.timestamp + 10000, 2, user1PhoneNumber);
    }

    function testBuyDataPlanRevertsIfNotEnoughEthSent() public {
        vm.startPrank(user1);
        vm.expectRevert(CountryInfo.CountryInfo__NotEnoughEthSent.selector);
        spain.buyDataPlan{value: 0.0000001 ether}(0, block.timestamp + 1000, 1, user1PhoneNumber);
    }

    function testBuyDataPlan() public {
        vm.startPrank(user1);
        spain.buyDataPlan{value: 45 ether}(0, block.timestamp + 1000, 1, user1PhoneNumber);
        uint256 price = 0.000001 ether * 1000;
        (
            uint256 startingTimestamp_,
            uint256 endingTimestamp_,
            uint16 plan_,
            uint256 priceOfSecondPlan_,
            uint256 amountPaid_,
            uint256 extraMoneyPaid_
        ) = spain.getUserPlan(user1PhoneNumber);
        assertEq(startingTimestamp_, block.timestamp);
        assertEq(endingTimestamp_, block.timestamp + 1000);
        assertEq(plan_, 1);
        assertEq(priceOfSecondPlan_, 0.000001 ether);
        assertEq(amountPaid_, 45 ether);
        assertEq(extraMoneyPaid_, 45 ether - price);
    }

    function testBuyDataPlan2TimesExtraMoneyCovers() public {
        vm.startPrank(user1);
        spain.buyDataPlan{value: 0.01 ether}(0, block.timestamp + 1000, 1, user1PhoneNumber);
        vm.warp(block.timestamp + 2000);
        spain.buyDataPlan{value: 0 ether}(0, block.timestamp + 1000, 1, user1PhoneNumber);
        (, uint256 endingTimestamp_,,,,) = spain.getUserPlan(user1PhoneNumber);
        assertEq(endingTimestamp_, block.timestamp + 1000);
    }

    function testBuyDataPlan2TimesExactCovered() public {
        vm.startPrank(user1);
        spain.buyDataPlan{value: 0.001 ether}(0, block.timestamp + 1000, 1, user1PhoneNumber);
        vm.warp(block.timestamp + 2000);
        spain.buyDataPlan{value: 45 ether}(0, block.timestamp + 1000, 1, user1PhoneNumber);
        uint256 price = 0.000001 ether * 1000;
        (
            uint256 startingTimestamp_,
            uint256 endingTimestamp_,
            uint16 plan_,
            uint256 priceOfSecondPlan_,
            uint256 amountPaid_,
            uint256 extraMoneyPaid_
        ) = spain.getUserPlan(user1PhoneNumber);
        assertEq(startingTimestamp_, block.timestamp);
        assertEq(endingTimestamp_, block.timestamp + 1000);
        assertEq(plan_, 1);
        assertEq(priceOfSecondPlan_, 0.000001 ether);
        assertEq(amountPaid_, 45.001 ether);
        assertEq(extraMoneyPaid_, 45 ether - price);
    }

    function testBuyDataPlan2TimesALittleCovered() public {
        vm.startPrank(user1);
        spain.buyDataPlan{value: 0.002 ether}(0, block.timestamp + 1000, 1, user1PhoneNumber);
        vm.warp(block.timestamp + 2000);
        spain.buyDataPlan{value: 0.003 ether}(0, block.timestamp + 2000, 1, user1PhoneNumber);
        (
             ,
            uint256 endingTimestamp_,
            uint16 plan_,
            uint256 priceOfSecondPlan_,
            uint256 amountPaid_,
            uint256 extraMoneyPaid_
        ) = spain.getUserPlan(user1PhoneNumber);
        assertEq(endingTimestamp_, block.timestamp + 2000);
        assertEq(plan_, 1);
        assertEq(priceOfSecondPlan_, 0.000001 ether);
        assertEq(amountPaid_, 0.005 ether);
        assertEq(extraMoneyPaid_, 0.002 ether);
    }

    //////////////////////////////
    ///extendPlan////////////////
    //////////////////////////////

    function testextendPlanRevertsIfNotInPlan() public {
        vm.startPrank(user2);
        vm.expectRevert(CountryInfo.CountryInfo__NeverBoughtAPlanBefore.selector);
        spain.extendPlan{value: 45 ether}(user2PhoneNumber, block.timestamp + 2000);
    }

    function testextendPlanRevertsIfBadEndingTimestamp() public {
        vm.startPrank(user1);
        spain.buyDataPlan{value: 25 ether}(0, block.timestamp + 1000, 1, user1PhoneNumber);
        vm.expectRevert(CountryInfo.CountryInfo__InvalidEndingTimestamp.selector);
        spain.extendPlan{value: 25 ether}(user1PhoneNumber, block.timestamp + 500);
    }

    function testextendPlanRevertsIfNotEnoughEthSent() public {
        vm.startPrank(user1);
        spain.buyDataPlan{value: 0.003 ether}(0, block.timestamp + 1000, 1, user1PhoneNumber);
        vm.expectRevert(CountryInfo.CountryInfo__NotEnoughEthSent.selector);
        spain.extendPlan{value: 0.001 ether}(user1PhoneNumber, block.timestamp + 500000000);
    }

    function testextendPlan() public {
        vm.startPrank(user1);
        spain.buyDataPlan{value: 0.003 ether}(0, block.timestamp + 1000, 1, user1PhoneNumber);
        spain.extendPlan{value: 0.001 ether}(user1PhoneNumber, block.timestamp + 1500);
        (
             ,
            uint256 endingTimestamp_,
             ,
             ,
            uint256 amountPaid_,
             
        ) = spain.getUserPlan(user1PhoneNumber);
        assertEq(endingTimestamp_, block.timestamp + 1500);
        assertEq(amountPaid_, 0.004 ether);
    }

    //////////////////////////////
    ///upgradePlan////////////////
    //////////////////////////////

    function testupgradePlanRevertsIfNotInAPlan() public {
        vm.startPrank(user1);
        vm.expectRevert(CountryInfo.CountryInfo__NeverBoughtAPlanBefore.selector);
        spain.upgradePlan{value: 0.003 ether}(user1PhoneNumber, 2);
    }

    function testupgradePlanRevertsIfNot() public {
        vm.startPrank(user1);
        spain.buyDataPlan{value: 0.003 ether}(0, block.timestamp + 500, 1, user1PhoneNumber);
        vm.warp(block.timestamp +1000);
        vm.expectRevert(CountryInfo.CountryInfo__InvalidEndingTimestamp.selector);
        spain.upgradePlan{value: 0.003 ether}(user1PhoneNumber, 2);
    }

    function testupgradePlanRevertsIfInvalidPlanId() public {
        vm.startPrank(user1);
        spain.buyDataPlan{value: 0.003 ether}(0, block.timestamp + 1000, 1, user1PhoneNumber);
        vm.warp(block.timestamp +500);
        vm.expectRevert(CountryInfo.CountryInfo__InvalidPlanId.selector);
        spain.upgradePlan{value: 0.003 ether}(user1PhoneNumber, 100);
    }

    function testupgradePlanRevertsIfNotEnoughEthSent() public {
        vm.startPrank(user1);
        spain.buyDataPlan{value: 0.003 ether}(0, block.timestamp + 1000, 1, user1PhoneNumber);
        vm.warp(block.timestamp +500);
        vm.expectRevert(CountryInfo.CountryInfo__NotEnoughEthSent.selector);
        spain.upgradePlan{value: 0.0000003 ether}(user1PhoneNumber, 2);
    }

    function testupgradePlan() public {
        vm.startPrank(user1);
        spain.buyDataPlan{value: 0.003 ether}(0, block.timestamp + 1000, 1, user1PhoneNumber);
        vm.warp(block.timestamp +500);
        spain.upgradePlan{value: 1 ether}(user1PhoneNumber, 3);
        (
             ,
             ,
            uint16 plan_,
            uint256 priceOfSecondPlan_,
            uint256 amountPaid_,
            
        ) = spain.getUserPlan(user1PhoneNumber);
        assertEq(amountPaid_, 1.003 ether );
        assertEq(priceOfSecondPlan_, 0.000015 ether);
        assertEq(plan_, 3);
    }

    //////////////////////////////
    ///cancelPlan////////////////
    //////////////////////////////

    function testcancelPlanRevertsIfNotInAPlan() public {
        vm.startPrank(user1);
        spain.buyDataPlan{value: 0.003 ether}(0, block.timestamp + 1000, 1, user1PhoneNumber);
        vm.warp(block.timestamp +1500);
        vm.expectRevert(CountryInfo.CountryInfo__InvalidEndingTimestamp.selector);
        spain.cancelPlan(user1PhoneNumber, user1);
    }

    function testcancelPlanBeforeStarting() public {
        vm.startPrank(user1);
        spain.buyDataPlan{value: 1 ether}(block.timestamp + 1000, block.timestamp + 101000, 1, user1PhoneNumber);
        spain.cancelPlan(user1PhoneNumber, user1);
        assertEq(spain.getFeesCollected(), 0.02002 ether);
        assertEq(user1.balance, 49.98098 ether);
    }

    function testcancelPlanMidway() public {
        vm.startPrank(user1);
        spain.buyDataPlan{value: 0.002 ether}(0, block.timestamp + 1001, 1, user1PhoneNumber);
        vm.warp(block.timestamp + 500);
        spain.cancelPlan(user1PhoneNumber, user1);
        assertEq(spain.getFeesCollected(), 0.00006 ether);
        assertEq(user1.balance,  49.99944 ether);     
    }

    



}
