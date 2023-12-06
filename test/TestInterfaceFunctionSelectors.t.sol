// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {IERC7540Deposit, IERC7540Redeem} from "src/interfaces/IERC7540.sol";

contract LiquidityPoolTest is Test {
  

    // --- erc165 checks ---
    function testERC165InterfaceSelectors() public {
        bytes4 erc7540Deposit = 0x1683f250;
        bytes4 erc7540Redeem = 0x0899cb0b;

        assertEq(type(IERC7540Deposit).interfaceId, erc7540Deposit);
        assertEq(type(IERC7540Redeem).interfaceId, erc7540Redeem);
    }
    
    function testERC165InterfaceSelectors() public {
        bytes4 erc7540Deposit = 0x1683f250;
        bytes4 erc7540Redeem = 0x0899cb0b;

        assertEq(type(IERC7540Deposit).interfaceId, erc7540Deposit);
        assertEq(type(IERC7540Redeem).interfaceId, erc7540Redeem);
    }
}