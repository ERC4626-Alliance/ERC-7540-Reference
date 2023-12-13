// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {IERC7540Deposit, IERC7540Redeem, IERC7540DepositReceiver, IERC7540RedeemReceiver} from "src/interfaces/IERC7540.sol";
import "src/interfaces/IERC7575.sol";

contract TestInterfaceFunctionSelectors is Test {
  

    // --- erc165 checks ---
    function testERC7540InterfaceSelectors() public {
        bytes4 erc7540Deposit = 0x1683f250;
        bytes4 erc7540Redeem = 0x0899cb0b;

        assertEq(type(IERC7540Deposit).interfaceId, erc7540Deposit);
        assertEq(type(IERC7540Redeem).interfaceId, erc7540Redeem);
    }

    function testERC7575InterfaceSelectors() public {
        bytes4 erc7575 = 0x2f0a18c5;
        bytes4 erc7575Minimal = 0x50a526d6;
        bytes4 erc7575Deposit = 0xc1f329ef;
        bytes4 erc7575Redeem = 0x2fd7d42a;
        bytes4 erc7575Withdraw = 0x70dec094;
        bytes4 erc7575Mint = 0xe1550342;


        assertEq(type(IERC7575).interfaceId, erc7575);
        assertEq(type(IERC7575MinimalVault).interfaceId, erc7575Minimal);
        assertEq(type(IERC7575DepositVault).interfaceId, erc7575Deposit);
        assertEq(type(IERC7575RedeemVault).interfaceId, erc7575Redeem);
        assertEq(type(IERC7575WithdrawVault).interfaceId, erc7575Withdraw);
        assertEq(type(IERC7575MintVault).interfaceId, erc7575Mint);
        
        // check the union as well
        assertEq(erc7575Minimal ^ erc7575Deposit ^ erc7575Redeem ^ erc7575Withdraw ^ erc7575Mint, erc7575);
    }
    
    function testReceiverInterfaceSelectors() public {
        bytes4 erc7540DepositReceiver = 0xe74d2a41;
        bytes4 erc7540RedeemReceiver = 0x0102fde4;

        assertEq(type(IERC7540DepositReceiver).interfaceId, erc7540DepositReceiver);
        assertEq(type(IERC7540DepositReceiver).interfaceId, bytes4(keccak256("onERC7540DepositReceived(address,address,uint256,bytes)")));
        assertEq(type(IERC7540RedeemReceiver).interfaceId, erc7540RedeemReceiver);
        assertEq(type(IERC7540RedeemReceiver).interfaceId, bytes4(keccak256("onERC7540RedeemReceived(address,address,uint256,bytes)")));
    }
}