// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {IERC7540Deposit, IERC7540Redeem, IERC7540Operator} from "src/interfaces/IERC7540.sol";
import {IERC165, IERC7575} from "src/interfaces/IERC7575.sol";
import {ControlledAsyncDeposit} from "src/ControlledAsyncDeposit.sol";
import {TimelockedAsyncRedeem} from "src/TimelockedAsyncRedeem.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract USDC is ERC20("USDC", "USDC", 6) {}

contract TestInterfaceFunctionSelectors is Test {
    // --- erc165 checks ---
    function testERC165InterfaceSelectors() public {
        bytes4 erc7540Deposit = 0xce3bbe50;
        bytes4 erc7540Redeem = 0x620ee8e4;
        bytes4 erc7575Vault = 0x2f0a18c5;
        bytes4 erc7540Operator = 0xe3bc4e65;
        bytes4 erc165 = 0x01ffc9a7;

        assertEq(type(IERC7540Deposit).interfaceId, erc7540Deposit);
        assertEq(type(IERC7540Redeem).interfaceId, erc7540Redeem);
        assertEq(type(IERC7540Operator).interfaceId, erc7540Operator);
        assertEq(type(IERC165).interfaceId, erc165);
        assertEq(type(IERC7575).interfaceId, erc7575Vault);

        ERC20 asset = new USDC();
        ControlledAsyncDeposit depositExample = new ControlledAsyncDeposit(asset, "Vault Share", "TEST");
        TimelockedAsyncRedeem redeemExample = new TimelockedAsyncRedeem(3 days, asset, "Vault Share", "TEST");

        assertTrue(depositExample.supportsInterface(erc7575Vault));
        assertTrue(depositExample.supportsInterface(erc7540Operator));
        assertTrue(depositExample.supportsInterface(erc165));
        assertTrue(redeemExample.supportsInterface(erc7575Vault));
        assertTrue(redeemExample.supportsInterface(erc7540Operator));
        assertTrue(redeemExample.supportsInterface(erc165));
    }
}
