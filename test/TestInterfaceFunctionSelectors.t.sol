// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {IERC7540Deposit, IERC7540Redeem, IERC7575, IERC7540Operator} from "src/interfaces/IERC7540.sol";
import {ERC7540AsyncDepositExample} from "src/ERC7540AsyncDepositExample.sol";
import {ERC7540AsyncRedeemExample} from "src/ERC7540AsyncRedeemExample.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract USDC is ERC20("USDC", "USDC", 6) {}

contract TestInterfaceFunctionSelectors is Test {
    // --- erc165 checks ---
    function testERC165InterfaceSelectors() public {
        bytes4 erc7540Deposit = 0xce3bbe50;
        bytes4 erc7540Redeem = 0x620ee8e4;
        bytes4 erc7575Vault = 0x2f0a18c5;
        bytes4 erc7540Operator = 0xe3bc4e65;

        assertEq(type(IERC7540Deposit).interfaceId, erc7540Deposit);
        assertEq(type(IERC7540Redeem).interfaceId, erc7540Redeem);
        assertEq(type(IERC7575).interfaceId, erc7575Vault);
        assertEq(type(IERC7540Operator).interfaceId, erc7540Operator);

        ERC20 asset = new USDC();
        ERC7540AsyncDepositExample depositExample = new ERC7540AsyncDepositExample(asset, "Vault Share", "TEST");
        ERC7540AsyncRedeemExample redeemExample = new ERC7540AsyncRedeemExample(asset, "Vault Share", "TEST");

        assertTrue(depositExample.supportsInterface(erc7575Vault));
        assertTrue(depositExample.supportsInterface(erc7540Operator));
        assertTrue(redeemExample.supportsInterface(erc7575Vault));
        assertTrue(redeemExample.supportsInterface(erc7540Operator));
    }
}
