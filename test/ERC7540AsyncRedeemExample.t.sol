// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {ERC7540AsyncRedeemExample} from "src/ERC7540AsyncRedeemExample.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract USDC is ERC20("USDC", "USDC", 6) {}

contract ERC7540AsyncRedeemExampleTest is Test {
    ERC7540AsyncRedeemExample public vault;
    ERC20 public asset;
    ERC20 public shareToken;
    address public owner;
    address public user;
    uint256 public initialAssetBalance = 1000e6; // 1000 USDC

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");

        // Deploy USDC and deal some to the user
        asset = new USDC();
        deal(address(asset), user, initialAssetBalance);

        // Deploy the vault
        vault = new ERC7540AsyncRedeemExample(asset, "Vault Share", "TEST");
        shareToken = ERC20(address(vault));

        // Deposit assets to the vault
        vm.startPrank(user);
        asset.approve(address(vault), initialAssetBalance);
        vault.deposit(initialAssetBalance, user);
        vm.stopPrank();
    }

    function testRequestRedeem() public {
        uint256 redeemAmount = 100e6;

        vm.startPrank(user);
        shareToken.approve(address(vault), redeemAmount);
        uint256 requestId = vault.requestRedeem(redeemAmount, user, user);
        vm.stopPrank();

        assertEq(requestId, 0, "Request ID should be 0");
        assertEq(vault.pendingRedeemRequest(0, user), redeemAmount, "Pending redeem should match requested amount");
        assertEq(vault.claimableRedeemRequest(0, user), 0, "Claimable redeem should be 0");
        assertEq(
            shareToken.balanceOf(user),
            initialAssetBalance - redeemAmount,
            "User should have less shares than initial balance"
        );
        assertEq(shareToken.balanceOf(address(vault)), redeemAmount, "Vault should have received share amount");
    }

    function testClaimableRedeemAfterDelay() public {
        uint256 redeemAmount = 100e6;

        vm.startPrank(user);
        shareToken.approve(address(vault), redeemAmount);
        vault.requestRedeem(redeemAmount, user, user);
        vm.stopPrank();

        // Fast forward 3 days
        vm.warp(block.timestamp + 3 days);

        assertEq(
            vault.claimableRedeemRequest(0, user),
            redeemAmount,
            "Claimable redeem should match requested amount after delay"
        );
    }

    function testWithdraw() public {
        uint256 redeemAmount = 100e6;
        uint256 expectedAssets = 100e6; // 100 USDC

        vm.startPrank(user);
        shareToken.approve(address(vault), redeemAmount);
        vault.requestRedeem(redeemAmount, user, user);
        vm.stopPrank();

        // Fast forward 3 days
        vm.warp(block.timestamp + 3 days);

        vm.prank(user);
        uint256 assets = vault.withdraw(expectedAssets, user, user);

        assertEq(assets, expectedAssets, "Withdrawn assets should equal expected amount");
        assertEq(asset.balanceOf(user), expectedAssets, "User should receive correct amount of assets");
        assertEq(vault.maxWithdraw(user), 0, "Max withdraw should be 0 after claiming");
    }

    function testRedeem() public {
        uint256 redeemAmount = 100e6;
        uint256 expectedAssets = 100e6; // 100 USDC

        vm.startPrank(user);
        shareToken.approve(address(vault), redeemAmount);
        vault.requestRedeem(redeemAmount, user, user);
        vm.stopPrank();

        // Fast forward 3 days
        vm.warp(block.timestamp + 3 days);

        vm.prank(user);
        uint256 assets = vault.redeem(redeemAmount, user, user);

        assertEq(assets, expectedAssets, "Redeemed assets should equal expected amount");
        assertEq(asset.balanceOf(user), expectedAssets, "User should receive correct amount of assets");
        assertEq(vault.maxRedeem(user), 0, "Max redeem should be 0 after claiming");
    }

    function testOperatorRequestRedeem() public {
        uint256 redeemAmount = 100e6;
        address operator = makeAddr("operator");

        // User approves the operator
        vm.prank(user);
        vault.setOperator(operator, true);

        // User approves the vault to spend their shares
        vm.prank(user);
        shareToken.approve(address(vault), redeemAmount);

        // Operator requests redeem on behalf of the user
        vm.prank(operator);
        uint256 requestId = vault.requestRedeem(redeemAmount, user, user);

        assertEq(requestId, 0, "Request ID should be 0");
        assertEq(vault.pendingRedeemRequest(0, user), redeemAmount, "Pending redeem should match requested amount");
        assertEq(vault.claimableRedeemRequest(0, user), 0, "Claimable redeem should be 0");
        assertEq(
            shareToken.balanceOf(user),
            initialAssetBalance - redeemAmount,
            "User should have less shares than initial balance"
        );
        assertEq(shareToken.balanceOf(address(vault)), redeemAmount, "Vault should have received share amount");
    }

    function testOperatorClaimRedeem() public {
        uint256 redeemAmount = 100e6;
        uint256 expectedAssets = 100e6; // 100 USDC
        address operator = makeAddr("operator");

        // User sets operator and approves the vault
        vm.startPrank(user);
        vault.setOperator(operator, true);
        shareToken.approve(address(vault), redeemAmount);
        vault.requestRedeem(redeemAmount, user, user);
        vm.stopPrank();

        // Fast forward 3 days
        vm.warp(block.timestamp + 3 days);

        vm.startPrank(operator);
        uint256 assets = vault.withdraw(vault.maxWithdraw(user), user, user);
        vm.stopPrank();

        assertEq(assets, expectedAssets, "Withdrawn assets should equal expected amount");
        assertEq(asset.balanceOf(user), expectedAssets, "User should receive correct amount of assets");
    }
}
