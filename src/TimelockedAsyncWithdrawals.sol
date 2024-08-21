// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {BaseERC7540} from "src/BaseERC7540.sol";
import {IERC7540Redeem} from "src/interfaces/IERC7540.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

// THIS VAULT IS AN UNOPTIMIZED, POTENTIALLY UNSECURE REFERENCE EXAMPLE AND IN NO WAY MEANT TO BE USED IN PRODUCTION

/**
 * @notice ERC7540 Implementing Delayed Async Withdrawals
 *
 *     This Vault has the following properties:
 *     - yield for the underlying asset is assumed to be transferred directly into the vault by some arbitrary mechanism
 *     - async redemptions are subject to a 3 day delay
 *     - new redemptions restart the 3 day delay even if the prior redemption is claimable.
 *         This can be resolved by using a more sophisticated algorithm for storing multiple requests.
 *     - the redemption exchange rate is locked in immediately upon request.
 */
abstract contract BaseTimelockedAsyncWithdrawals is BaseERC7540, IERC7540Redeem {
    using FixedPointMathLib for uint256;

    uint32 public constant TIMELOCK = 3 days;

    uint256 internal _totalPendingRedeemAssets;
    mapping(address => RedemptionRequest) internal _pendingRedemption;

    struct RedemptionRequest {
        uint256 assets;
        uint256 shares;
        uint32 claimableTimestamp;
    }

    function totalAssets() public view virtual override returns (uint256) {
        return ERC20(asset).balanceOf(address(this)) - _totalPendingRedeemAssets;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC7540 LOGIC
    //////////////////////////////////////////////////////////////*/

    function requestRedeem(uint256 shares, address controller, address owner) external returns (uint256 requestId) {
        require(owner == msg.sender || isOperator[owner][msg.sender], "ERC7540Vault/invalid-owner");
        require(ERC20(address(this)).balanceOf(owner) >= shares, "ERC7540Vault/insufficient-balance");
        require(shares != 0, "ZERO_SHARES");

        uint256 assets = convertToAssets(shares);

        SafeTransferLib.safeTransferFrom(this, owner, address(this), shares);

        _pendingRedemption[controller] =
            RedemptionRequest({assets: assets, shares: shares, claimableTimestamp: uint32(block.timestamp) + TIMELOCK});

        _totalPendingRedeemAssets += assets;

        emit RedeemRequest(controller, owner, REQUEST_ID, msg.sender, shares);
        return REQUEST_ID;
    }

    function pendingRedeemRequest(uint256, address controller) public view returns (uint256 pendingShares) {
        RedemptionRequest memory request = _pendingRedemption[controller];
        if (request.claimableTimestamp > block.timestamp) {
            return request.shares;
        }
        return 0;
    }

    function claimableRedeemRequest(uint256, address controller) public view returns (uint256 claimableShares) {
        RedemptionRequest memory request = _pendingRedemption[controller];
        if (request.claimableTimestamp <= block.timestamp && request.shares > 0) {
            return request.shares;
        }
        return 0;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC4626 OVERRIDDEN LOGIC
    //////////////////////////////////////////////////////////////*/

    function withdraw(uint256 assets, address receiver, address controller)
        public
        virtual
        override
        returns (uint256 shares)
    {
        require(controller == msg.sender || isOperator[controller][msg.sender], "ERC7540Vault/invalid-caller");
        require(assets != 0, "Must claim nonzero amount");

        RedemptionRequest storage request = _pendingRedemption[controller];
        require(request.claimableTimestamp <= block.timestamp, "ERC7540Vault/not-claimable-yet");

        // Claiming partially introduces precision loss. The user therefore receives a rounded down amount,
        // while the claimable balance is reduced by a rounded up amount.
        shares = assets.mulDivDown(request.shares, request.assets);
        uint256 sharesUp = assets.mulDivUp(request.shares, request.assets);

        request.assets -= assets;
        request.shares = request.shares > sharesUp ? request.shares - sharesUp : 0;

        _totalPendingRedeemAssets -= assets;

        SafeTransferLib.safeTransfer(asset, receiver, assets);

        emit Withdraw(msg.sender, receiver, controller, assets, shares);
    }

    function redeem(uint256 shares, address receiver, address controller)
        public
        virtual
        override
        returns (uint256 assets)
    {
        require(controller == msg.sender || isOperator[controller][msg.sender], "ERC7540Vault/invalid-caller");
        require(shares != 0, "Must claim nonzero amount");

        RedemptionRequest storage request = _pendingRedemption[controller];
        require(request.claimableTimestamp <= block.timestamp, "ERC7540Vault/not-claimable-yet");

        assets = shares.mulDivDown(request.assets, request.shares);
        uint256 assetsUp = shares.mulDivUp(request.assets, request.shares);

        request.assets = request.assets > assetsUp ? request.assets - assetsUp : 0;
        request.shares -= shares;

        _totalPendingRedeemAssets -= assets;

        SafeTransferLib.safeTransfer(asset, receiver, assets);

        emit Withdraw(msg.sender, receiver, controller, assets, shares);
    }

    function maxWithdraw(address controller) public view virtual override returns (uint256) {
        RedemptionRequest memory request = _pendingRedemption[controller];
        if (request.claimableTimestamp <= block.timestamp) {
            return request.assets;
        }
        return 0;
    }

    function maxRedeem(address controller) public view virtual override returns (uint256) {
        RedemptionRequest memory request = _pendingRedemption[controller];
        if (request.claimableTimestamp <= block.timestamp) {
            return request.shares;
        }
        return 0;
    }

    // Preview functions always revert for async flows
    function previewWithdraw(uint256) public pure virtual override returns (uint256) {
        revert("ERC7540Vault/async-flow");
    }

    function previewRedeem(uint256) public pure virtual override returns (uint256) {
        revert("ERC7540Vault/async-flow");
    }

    /*//////////////////////////////////////////////////////////////
                        ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(IERC7540Redeem).interfaceId || super.supportsInterface(interfaceId);
    }
}

contract TimelockedAsyncWithdrawals is BaseTimelockedAsyncWithdrawals {
    constructor(ERC20 _asset, string memory _name, string memory _symbol) BaseERC7540(_asset, _name, _symbol) {}
}
