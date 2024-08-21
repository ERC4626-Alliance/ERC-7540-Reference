// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC7540Deposit, IERC7540Redeem} from "src/interfaces/IERC7540.sol";
import {BaseERC7540} from "src/BaseERC7540.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {BaseControlledAsyncDeposits} from "src/ControlledAsyncDeposits.sol";
import {BaseTimelockedAsyncWithdrawals} from "src/TimelockedAsyncWithdrawals.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract FullyAsyncVault is BaseControlledAsyncDeposits, BaseTimelockedAsyncWithdrawals {
    constructor(ERC20 _asset, string memory _name, string memory _symbol)
        BaseControlledAsyncDeposits()
        BaseTimelockedAsyncWithdrawals()
        BaseERC7540(_asset, _name, _symbol)
    {}

    function totalAssets()
        public
        view
        virtual
        override(BaseControlledAsyncDeposits, BaseTimelockedAsyncWithdrawals)
        returns (uint256)
    {
        return ERC20(asset).balanceOf(address(this)) - _totalPendingDepositAssets - _totalPendingRedeemAssets;
    }

    function maxDeposit(address controller)
        public
        view
        virtual
        override(BaseControlledAsyncDeposits, ERC4626)
        returns (uint256)
    {
        return BaseControlledAsyncDeposits.maxDeposit(controller);
    }

    function previewDeposit(uint256)
        public
        pure
        virtual
        override(BaseControlledAsyncDeposits, ERC4626)
        returns (uint256)
    {
        revert("ERC7540Vault/async-flow");
    }

    function deposit(uint256 assets, address receiver)
        public
        virtual
        override(BaseControlledAsyncDeposits, ERC4626)
        returns (uint256 shares)
    {
        shares = BaseControlledAsyncDeposits.deposit(assets, receiver, receiver);
    }

    function maxMint(address controller)
        public
        view
        virtual
        override(BaseControlledAsyncDeposits, ERC4626)
        returns (uint256)
    {
        return BaseControlledAsyncDeposits.maxMint(controller);
    }

    function previewMint(uint256)
        public
        pure
        virtual
        override(BaseControlledAsyncDeposits, ERC4626)
        returns (uint256)
    {
        revert("ERC7540Vault/async-flow");
    }

    function mint(uint256 shares, address receiver)
        public
        virtual
        override(BaseControlledAsyncDeposits, ERC4626)
        returns (uint256 assets)
    {
        assets = BaseControlledAsyncDeposits.mint(shares, receiver, receiver);
    }

    function maxWithdraw(address controller)
        public
        view
        virtual
        override(BaseTimelockedAsyncWithdrawals, ERC4626)
        returns (uint256)
    {
        return BaseTimelockedAsyncWithdrawals.maxWithdraw(controller);
    }

    function previewWithdraw(uint256)
        public
        pure
        virtual
        override(BaseTimelockedAsyncWithdrawals, ERC4626)
        returns (uint256)
    {
        revert("ERC7540Vault/async-flow");
    }

    function withdraw(uint256 assets, address receiver, address controller)
        public
        virtual
        override(BaseTimelockedAsyncWithdrawals, ERC4626)
        returns (uint256 shares)
    {
        shares = BaseTimelockedAsyncWithdrawals.withdraw(assets, receiver, controller);
    }

    function maxRedeem(address controller)
        public
        view
        virtual
        override(BaseTimelockedAsyncWithdrawals, ERC4626)
        returns (uint256)
    {
        return BaseTimelockedAsyncWithdrawals.maxRedeem(controller);
    }

    function previewRedeem(uint256)
        public
        pure
        virtual
        override(BaseTimelockedAsyncWithdrawals, ERC4626)
        returns (uint256)
    {
        revert("ERC7540Vault/async-flow");
    }

    function redeem(uint256 shares, address receiver, address controller)
        public
        virtual
        override(BaseTimelockedAsyncWithdrawals, ERC4626)
        returns (uint256 assets)
    {
        assets = BaseTimelockedAsyncWithdrawals.redeem(shares, receiver, controller);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(BaseControlledAsyncDeposits, BaseTimelockedAsyncWithdrawals)
        returns (bool)
    {
        return interfaceId == type(IERC7540Deposit).interfaceId || interfaceId == type(IERC7540Redeem).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
