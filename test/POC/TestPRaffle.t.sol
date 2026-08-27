//SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import {Test, console2} from "forge-std/Test.sol";
import {PuppyRaffle} from "../../src/PuppyRaffle.sol";
import {DeployPuppyRaffle} from "../../script/DeployPuppyRaffle.s.sol";
import {AttackPRaffle} from "../../src/POC/AttackPRaffle.sol";

contract TestPRaffle is Test {
    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    DeployPuppyRaffle deployer;
    PuppyRaffle pRaffle;
    AttackPRaffle attackPRaffle;

    address spider = makeAddr("spider");
    address alice = makeAddr("alie");
    address bob = makeAddr("bob");
    address dan = makeAddr("dan");
    address eli = makeAddr("eli");

    address constant DEFAULT_FOUNDRY = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    uint256 public STARTING_AMOUNT = 1e18;

    function setUp() public {
        deployer = new DeployPuppyRaffle();
        pRaffle = deployer.run();

        attackPRaffle = new AttackPRaffle(address(pRaffle));

        vm.deal(spider, 10e18);
        vm.deal(alice, STARTING_AMOUNT);
        vm.deal(bob, STARTING_AMOUNT);
        vm.deal(dan, STARTING_AMOUNT);
        vm.deal(eli, STARTING_AMOUNT);
        vm.deal(DEFAULT_FOUNDRY, STARTING_AMOUNT);
        vm.deal(address(attackPRaffle), STARTING_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier playersToEnterInRaffle() {
        //Arrange

        address[] memory the_players = new address[](5);

        the_players[0] = spider;
        the_players[1] = alice;
        the_players[2] = bob;
        the_players[3] = dan;
        the_players[4] = eli;

        //Act
        vm.prank(spider);
        pRaffle.enterRaffle{value: STARTING_AMOUNT * 5}(the_players);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            FUNCTIONAL TEST
    //////////////////////////////////////////////////////////////*/

    function test_owner_and_user_ether_balance() public {
        //Arrange
        address owner_of_raffle_contract = pRaffle.owner();

        uint256 eth_of_spider = spider.balance;
        uint256 eth_of_alice = alice.balance;
        uint256 eth_of_DF = DEFAULT_FOUNDRY.balance;

        //Act//Assert

        console2.log("owner of the Contract: ", owner_of_raffle_contract);
        console2.log("Eth of spider: ", eth_of_spider);

        console2.log("Eth of alice: ", eth_of_alice);
        console2.log("Eth of default foundry: ", eth_of_DF);
    }

    function test_enterRaffle() public {
        //Arrange
        address[] memory the_players = new address[](5);

        the_players[0] = spider;
        the_players[1] = alice;
        the_players[2] = bob;
        the_players[3] = dan;
        the_players[4] = eli;

        //Act
        pRaffle.enterRaffle{value: STARTING_AMOUNT * 5}(the_players);

        //Assert
        assertEq(pRaffle.getActivePlayerIndex(spider), 0);
        assertEq(pRaffle.getActivePlayerIndex(alice), 1);
        assertEq(pRaffle.getActivePlayerIndex(bob), 2);
        assertEq(pRaffle.getActivePlayerIndex(dan), 3);
        assertEq(pRaffle.getActivePlayerIndex(eli), 4);
    }

    function test_RevertIf_Spider_tries_to_enter_Raffle_twice() public {
        //Arrange
        address[] memory the_players = new address[](6);

        the_players[0] = spider;
        the_players[1] = alice;
        the_players[2] = bob;
        the_players[3] = dan;
        the_players[4] = eli;
        the_players[5] = spider;

        //Act
        vm.expectRevert();
        pRaffle.enterRaffle{value: STARTING_AMOUNT * 6}(the_players);

        uint256 balance_of_contract_after_A_duplicate_attempt = address(pRaffle).balance;

        // console2.log(balance_of_contract_after_A_duplicate_attempt);
        //Assert

        assertEq(balance_of_contract_after_A_duplicate_attempt, 0, "should be 5 ether as spider is duplicate");
    }

    function test_If_A_Address_Is_A_ZeroAddress() public {
        //Arrange
        vm.startPrank(spider);
        address[] memory the_players = new address[](6);

        the_players[0] = spider;
        the_players[1] = alice;
        the_players[2] = bob;
        the_players[3] = dan;
        the_players[4] = eli;
        the_players[5] = address(0);
        //Act
        pRaffle.enterRaffle{value: STARTING_AMOUNT * 6}(the_players);
        uint256 balance_of_contract_after_Allowing_a_zeroAddress = address(pRaffle).balance;

        console2.log(balance_of_contract_after_Allowing_a_zeroAddress);
        vm.stopPrank();

        //Assert

        assertEq(balance_of_contract_after_Allowing_a_zeroAddress, 6 ether, "should be 5 ether as spider is duplicate");
    } //bug 01

    function test_Refund() public playersToEnterInRaffle {
        //Arrange
        //Act
        uint256 balance_Of_contract_before_spider_refund = address(pRaffle).balance;

        console2.log(
            "Balance of Contract Before Spider refunds the balance: ", balance_Of_contract_before_spider_refund
        );

        vm.prank(spider);
        pRaffle.refund(0);

        uint256 balance_Of_contract_after_spider_refund = address(pRaffle).balance;

        console2.log("Balance of Contract after Spider refunds the balance: ", balance_Of_contract_after_spider_refund);
        //Assert
        assertEq(balance_Of_contract_before_spider_refund, 5 ether, "As spider enter raffle with 5 raffle");
        assertEq(
            balance_Of_contract_after_spider_refund,
            balance_Of_contract_before_spider_refund - 1e18,
            "Spider refunds its fund"
        );
    }

    function test_Revert_if_spider_tries_to_refund_alice_funds() public playersToEnterInRaffle {
        //Arrange

        uint256 balance_Of_contract_before_spider_refunds_the_alice_funds = address(pRaffle).balance;

        console2.log(
            "Balance of Contract before spider refunds the alice_funds: ",
            balance_Of_contract_before_spider_refunds_the_alice_funds
        );
        //Act
        vm.prank(spider);
        vm.expectRevert();
        pRaffle.refund(1);

        uint256 balance_Of_contract_after_spider_tries_to_refund_alice_funds = address(pRaffle).balance;

        console2.log(
            "Balance of Contract after spider tries to refund alice_funds: ",
            balance_Of_contract_after_spider_tries_to_refund_alice_funds
        );

        //Assert
        assertEq(
            balance_Of_contract_after_spider_tries_to_refund_alice_funds,
            balance_Of_contract_before_spider_refunds_the_alice_funds,
            "Should be same it should reverts"
        );
    }

    function test_AfterRefund_array_Size_changes() public playersToEnterInRaffle {
        //Arrange
        vm.prank(spider);
        pRaffle.refund(0);

        uint256 balance_Of_contract_after_spider_refund = address(pRaffle).balance;

        console2.log("Balance of Contract after Spider refunds the balance: ", balance_Of_contract_after_spider_refund);
        //Act
        //Assert
        assertEq(pRaffle.getActivePlayerIndex(address(0)), 0);

        assertEq(pRaffle.getActivePlayerIndex(alice), 1);

        assertEq(pRaffle.getActivePlayerIndex(bob), 2);
        assertEq(pRaffle.getActivePlayerIndex(dan), 3);
        assertEq(pRaffle.getActivePlayerIndex(eli), 4);
    }

    function test_Fails_to_selectWinner() public playersToEnterInRaffle {
        //Arrange
        //Act
        vm.prank(spider);
        pRaffle.refund(0);
        vm.prank(alice);
        pRaffle.refund(1);

        uint256 balance_of_contract = address(pRaffle).balance;
        console2.log("Balance of Contract: ", balance_of_contract);

        vm.warp(2 days);

        vm.startPrank(spider);
        vm.expectRevert();
        pRaffle.selectWinner();
        vm.stopPrank();

        uint256 balance_of_after_calling_selectWinner_function = address(pRaffle).balance;
        console2.log("Balance of Contract: ", balance_of_after_calling_selectWinner_function);

        uint256 totalFees = pRaffle.totalFees();
        console2.log("Total Fees: ", totalFees);
        //Assert
        assertEq(
            balance_of_contract,
            balance_of_after_calling_selectWinner_function,
            "As 2 people Refunded but the state doesnt track it"
        );
    } //bug 02
}
