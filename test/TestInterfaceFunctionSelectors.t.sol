// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {IERC7540Deposit, IERC7540Redeem} from "src/interfaces/IERC7540.sol";

contract LiquidityPoolTest is Test {
  

    // --- erc165 checks ---
    function testERC165Support( /*bytes4 unsupportedInterfaceId */) public {
        bytes4 erc165 = 0x01ffc9a7;
        bytes4 erc7540Deposit = 0x1683f250;
        bytes4 erc7540Redeem = 0x0899cb0b;

        // vm.assume(unsupportedInterfaceId != erc165 && unsupportedInterfaceId != erc7540Deposit && unsupportedInterfaceId != erc7540Redeem);

        // address lPool_ = deploySimplePool();
        // LiquidityPool lPool = LiquidityPool(lPool_);

        assertEq(type(IERC7540Deposit).interfaceId, erc7540Deposit);
        assertEq(type(IERC7540Redeem).interfaceId, erc7540Redeem);

        // assertEq(lPool.supportsInterface(erc165), true);
        // assertEq(lPool.supportsInterface(erc7540Deposit), true);
        // assertEq(lPool.supportsInterface(erc7540Redeem), true);

        // assertEq(lPool.supportsInterface(unsupportedInterfaceId), false);
    }
    
}