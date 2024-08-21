// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {ControlledAsyncDeposits} from "src/ControlledAsyncDeposits.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract USDC is ERC20("USDC", "USDC", 6) {}

contract ControlledAsyncDepositsTest is Test {
    ControlledAsyncDeposits public vault;
    ERC20 public asset;
    address public owner;
    address public user;
    uint256 public initialAssetBalance = 1000e6;

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");

        // Deal some USDC to the user
        asset = new USDC();
        deal(address(asset), user, initialAssetBalance);

        // Deploy the vault
        vault = new ControlledAsyncDeposits(asset, "Vault Share", "TEST");
    }

    function testRequestDeposit() public {
        uint256 depositAmount = 100e6;

        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        uint256 requestId = vault.requestDeposit(depositAmount, user, user);
        vm.stopPrank();

        assertEq(requestId, 0, "Request ID should be 0");
        assertEq(vault.pendingDepositRequest(0, user), depositAmount, "Pending deposit should match requested amount");
        assertEq(vault.claimableDepositRequest(0, user), 0, "Claimable deposit should be 0");
        assertEq(
            asset.balanceOf(user),
            initialAssetBalance - depositAmount,
            "User should have less USDC than initial balance"
        );
        assertEq(asset.balanceOf(address(vault)), depositAmount, "Vault should have received deposit amount");
    }

    function testFulfillDeposit() public {
        uint256 depositAmount = 100e6;

        // First, request a deposit
        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        vault.requestDeposit(depositAmount, user, user);
        vm.stopPrank();

        // Then, fulfill the deposit as the owner
        uint256 shares = vault.fulfillDeposit(user, depositAmount);

        assertEq(shares, depositAmount, "Shares should equal deposit amount");
        assertEq(
            vault.claimableDepositRequest(0, user), depositAmount, "Claimable deposit should match fulfilled amount"
        );
    }

    function testDeposit() public {
        uint256 depositAmount = 100e6;

        // Request and fulfill a deposit first
        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        vault.requestDeposit(depositAmount, user, user);
        vm.stopPrank();

        vault.fulfillDeposit(user, depositAmount);

        // Now claim the deposit
        vm.prank(user);
        uint256 shares = vault.deposit(depositAmount, user, user);

        assertEq(shares, depositAmount, "Received shares should equal deposit amount");
        assertEq(ERC20(vault).balanceOf(user), shares, "User should receive correct number of shares");
    }

    function testOperatorRequestDeposit() public {
        uint256 depositAmount = 100e6;
        address operator = makeAddr("operator");

        // User approves the operator
        vm.prank(user);
        vault.setOperator(operator, true);

        // User approves the vault to spend their tokens
        vm.prank(user);
        asset.approve(address(vault), depositAmount);

        // Operator requests deposit on behalf of the user
        vm.prank(operator);
        uint256 requestId = vault.requestDeposit(depositAmount, user, user);

        assertEq(requestId, 0, "Request ID should be 0");
        assertEq(vault.pendingDepositRequest(0, user), depositAmount, "Pending deposit should match requested amount");
        assertEq(vault.claimableDepositRequest(0, user), 0, "Claimable deposit should be 0");
        assertEq(
            asset.balanceOf(user),
            initialAssetBalance - depositAmount,
            "User should have less USDC than initial balance"
        );
        assertEq(asset.balanceOf(address(vault)), depositAmount, "Vault should have received deposit amount");
    }

    function testOperatorClaimDeposit() public {
        uint256 depositAmount = 100e6;
        address operator = makeAddr("operator");

        // User sets operator and approves the vault
        vm.startPrank(user);
        vault.setOperator(operator, true);
        asset.approve(address(vault), depositAmount);
        vm.stopPrank();

        // Operator requests a deposit
        vm.prank(operator);
        vault.requestDeposit(depositAmount, user, user);

        vault.fulfillDeposit(user, depositAmount);

        vm.startPrank(operator);
        uint256 shares = vault.deposit(vault.maxDeposit(user), user, user);
        vm.stopPrank();

        assertEq(shares, depositAmount, "Shares should equal deposit amount");
        assertEq(ERC20(vault).balanceOf(user), shares, "User should receive correct number of shares");
    }
}
