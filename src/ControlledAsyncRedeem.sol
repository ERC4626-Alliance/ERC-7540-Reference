// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {BaseERC7540} from "src/BaseERC7540.sol";
import {IERC7540Redeem} from "src/interfaces/IERC7540.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

// THIS VAULT IS AN UNOPTIMIZED, POTENTIALLY UNSECURE REFERENCE EXAMPLE AND IN NO WAY MEANT TO BE USED IN PRODUCTION

/**
 * @notice ERC7540 Implementing Controlled Async Redeem
 *
 *     This Vault has the following properties:
 *     - yield for the underlying asset is assumed to be transferred directly into the vault by some arbitrary mechanism
 *     - async redemptions are subject to approval by an owner account
 */
abstract contract BaseControlledAsyncRedeem is BaseERC7540, IERC7540Redeem {
    using FixedPointMathLib for uint256;

    mapping(address => PendingRedeem) internal _pendingRedeem;
    mapping(address => ClaimableRedeem) internal _claimableRedeem;

    struct PendingRedeem {
        uint256 shares;
    }

    struct ClaimableRedeem {
        uint256 assets;
        uint256 shares;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC7540 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice this deposit request is added to any pending deposit request
    function requestRedeem(uint256 shares, address controller, address owner) external returns (uint256 requestId) {
        require(owner == msg.sender || isOperator[owner][msg.sender], "ERC7540Vault/invalid-owner");
        require(ERC20(address(this)).balanceOf(owner) >= shares, "ERC7540Vault/insufficient-balance");
        require(shares != 0, "ZERO_SHARES");

        SafeTransferLib.safeTransferFrom(this, owner, address(this), shares);

        uint256 currentPendingShares = _pendingRedeem[controller].shares;
        _pendingRedeem[controller] = PendingRedeem(shares + currentPendingShares);

        emit RedeemRequest(controller, owner, REQUEST_ID, msg.sender, shares);
        return REQUEST_ID;
    }

    function pendingRedeemRequest(uint256, address controller) public view returns (uint256 pendingShares) {
        pendingShares = _pendingRedeem[controller].shares;
    }

    function claimableRedeemRequest(uint256, address controller) public view returns (uint256 claimableShares) {
        claimableShares = _claimableRedeem[controller].shares;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT FULFILLMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function fulfillRedeem(address controller, uint256 shares) public onlyOwner returns (uint256 assets) {
        PendingRedeem storage request = _pendingRedeem[controller];
        require(request.shares != 0 && shares <= request.shares, "ZERO_SHARES");

        assets = convertToAssets(shares);

        _claimableRedeem[controller] =
            ClaimableRedeem(_claimableRedeem[controller].assets + assets, _claimableRedeem[controller].shares + shares);

        request.shares -= shares;
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

        // Claiming partially introduces precision loss. The user therefore receives a rounded down amount,
        // while the claimable balance is reduced by a rounded up amount.
        ClaimableRedeem storage claimable = _claimableRedeem[controller];
        shares = assets.mulDivDown(claimable.shares, claimable.assets);
        uint256 sharesUp = assets.mulDivUp(claimable.shares, claimable.assets);

        claimable.assets -= assets;
        claimable.shares = claimable.shares > sharesUp ? claimable.shares - sharesUp : 0;

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

        // Claiming partially introduces precision loss. The user therefore receives a rounded down amount,
        // while the claimable balance is reduced by a rounded up amount.
        ClaimableRedeem storage claimable = _claimableRedeem[controller];
        assets = shares.mulDivDown(claimable.assets, claimable.shares);
        uint256 assetsUp = shares.mulDivUp(claimable.assets, claimable.shares);

        claimable.assets = claimable.assets > assetsUp ? claimable.assets - assetsUp : 0;
        claimable.shares -= shares;

        SafeTransferLib.safeTransfer(asset, receiver, assets);

        emit Withdraw(msg.sender, receiver, controller, assets, shares);
    }

    function maxWithdraw(address controller) public view virtual override returns (uint256) {
        return _claimableRedeem[controller].assets;
    }

    function maxRedeem(address controller) public view virtual override returns (uint256) {
        return _claimableRedeem[controller].shares;
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

contract ControlledAsyncRedeem is BaseControlledAsyncRedeem {
    constructor(ERC20 _asset, string memory _name, string memory _symbol) BaseERC7540(_asset, _name, _symbol) {}
}
