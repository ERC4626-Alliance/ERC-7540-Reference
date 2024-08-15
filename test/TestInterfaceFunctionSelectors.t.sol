// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {IERC7540Deposit, IERC7540Redeem} from "src/interfaces/IERC7540.sol";

contract TestInterfaceFunctionSelectors is Test {
  

    // --- erc165 checks ---
    function testERC165InterfaceSelectors() public {
        bytes4 erc7540Deposit = 0x1683f250;
        bytes4 erc7540Redeem = 0x0899cb0b;

        assertEq(type(IERC7540Deposit).interfaceId, erc7540Deposit);
        assertEq(type(IERC7540Redeem).interfaceId, erc7540Redeem);
    }
    
    function testReceiverInterfaceSelectors() public {
        bytes4 erc7540DepositReceiver = 0xe74d2a41;
        bytes4 erc7540RedeemReceiver = 0x0102fde4;

        // assertEq(type(IERC7540DepositReceiver).interfaceId, erc7540DepositReceiver);
        // assertEq(type(IERC7540DepositReceiver).interfaceId, bytes4(keccak256("onERC7540DepositReceived(address,address,uint256,bytes)")));
        // assertEq(type(IERC7540RedeemReceiver).interfaceId, erc7540RedeemReceiver);
        // assertEq(type(IERC7540RedeemReceiver).interfaceId, bytes4(keccak256("onERC7540RedeemReceived(address,address,uint256,bytes)")));
    }
}