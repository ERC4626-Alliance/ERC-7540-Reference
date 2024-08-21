// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {BaseERC7540} from "src/BaseERC7540.sol";
import {BaseControlledAsyncDeposits} from "src/ControlledAsyncDeposits.sol";
import {BaseTimelockedAsyncWithdrawals} from "src/TimelockedAsyncWithdrawals.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract FullyAsyncVault is BaseControlledAsyncDeposits, BaseTimelockedAsyncWithdrawals {
    constructor(ERC20 _asset, string memory _name, string memory _symbol)
        BaseControlledAsyncDeposits()
        BaseTimelockedAsyncWithdrawals()
        BaseERC7540(_asset, _name, _symbol)
    {}
}
