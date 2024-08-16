// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC7540Redeem} from "src/interfaces/IERC7540.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {IERC4626} from "src/interfaces/IERC4626.sol";
import {IERC165} from "src/interfaces/IERC7575.sol";
import {SafeTransferLib} from "src/libraries/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";


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
 *     - users can only redeem the maximum amount.
 *         To allow partial claims, the redeem and withdraw functions would need to allow for pro rata claims.
 *         Conversions between claimable assets/shares should be checked for rounding safety.
 */
contract ERC7540AsyncRedeemExample is IERC7540Redeem, ERC4626, Owned {
    /// @dev Assume requests are non-fungible and all have ID = 0
    uint256 private constant REQUEST_ID = 0;

    uint8 internal immutable _shareDecimals;

    mapping(address => RedemptionRequest) internal _pendingRedemption;
    uint256 internal _totalPendingAssets;
    mapping(address => mapping(address => bool)) public isOperator;

    uint32 public constant REDEEM_DELAY_SECONDS = 3 days;

    struct RedemptionRequest {
        uint256 assets;
        uint256 shares;
        uint32 claimableTimestamp;
    }

    constructor(ERC20 _asset, string memory _name, string memory _symbol)
        Owned(msg.sender)
        ERC4626(_asset, _name, _symbol)
    {}

    function totalAssets() public view override returns (uint256) {
        return ERC20(asset).balanceOf(address(this)) - _totalPendingAssets;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC7540 LOGIC
    //////////////////////////////////////////////////////////////*/

    function requestRedeem(uint256 shares, address controller, address owner) external returns (uint256 requestId) {
        require(owner == msg.sender || isOperator[owner][msg.sender], "ERC7540Vault/invalid-owner");
        require(ERC20(address(this)).balanceOf(owner) >= shares, "ERC7540Vault/insufficient-balance");
        require(shares != 0, "ZERO_SHARES");

        uint256 assets = convertToAssets(shares);

        SafeTransferLib.safeTransferFrom(address(this), owner, address(this), shares);

        _pendingRedemption[controller] = RedemptionRequest({
            assets: assets,
            shares: shares,
            claimableTimestamp: uint32(block.timestamp) + REDEEM_DELAY_SECONDS
        });

        _totalPendingAssets += assets;

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

    function setOperator(address operator, bool approved) public virtual returns (bool success) {
        require(msg.sender != operator, "ERC7540Vault/cannot-set-self-as-operator");
        isOperator[msg.sender][operator] = approved;
        emit OperatorSet(msg.sender, operator, approved);
        success = true;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC4626 OVERRIDDEN LOGIC
    //////////////////////////////////////////////////////////////*/

    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256 shares) {
        require(owner == msg.sender || isOperator[owner][msg.sender], "ERC7540Vault/invalid-caller");
        require(assets != 0 && assets == maxWithdraw(owner), "Must claim nonzero maximum");

        RedemptionRequest storage request = _pendingRedemption[owner];
        require(request.claimableTimestamp <= block.timestamp, "ERC7540Vault/not-claimable-yet");

        shares = request.shares;
        uint256 claimableAssets = request.assets;

        delete _pendingRedemption[owner];
        _totalPendingAssets -= claimableAssets;

        SafeTransferLib.safeTransfer(address(asset), receiver, claimableAssets);

        emit Withdraw(msg.sender, receiver, owner, claimableAssets, shares);
    }

    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256 assets) {
        require(owner == msg.sender || isOperator[owner][msg.sender], "ERC7540Vault/invalid-caller");
        require(shares != 0 && shares == maxRedeem(owner), "Must claim nonzero maximum");

        RedemptionRequest storage request = _pendingRedemption[owner];
        require(request.claimableTimestamp <= block.timestamp, "ERC7540Vault/not-claimable-yet");

        assets = request.assets;

        delete _pendingRedemption[owner];
        _totalPendingAssets -= assets;

        SafeTransferLib.safeTransfer(address(asset), receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function maxWithdraw(address controller) public view override returns (uint256) {
        RedemptionRequest memory request = _pendingRedemption[controller];
        if (request.claimableTimestamp <= block.timestamp) {
            return request.assets;
        }
        return 0;
    }

    function maxRedeem(address controller) public view override returns (uint256) {
        RedemptionRequest memory request = _pendingRedemption[controller];
        if (request.claimableTimestamp <= block.timestamp) {
            return request.shares;
        }
        return 0;
    }

    // --- ERC165 support ---
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC7540Redeem).interfaceId || interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IERC4626).interfaceId;
    }

    // Preview functions always revert for async flows
    function previewWithdraw(uint256) public pure override returns (uint256) {
        revert("ERC7540Vault/async-flow");
    }

    function previewRedeem(uint256) public pure override returns (uint256) {
        revert("ERC7540Vault/async-flow");
    }
}
