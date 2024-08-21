// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {BaseERC7540} from "src/BaseERC7540.sol";
import {IERC7540Deposit} from "src/interfaces/IERC7540.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

// THIS VAULT IS AN UNOPTIMIZED, POTENTIALLY UNSECURE REFERENCE EXAMPLE AND IN NO WAY MEANT TO BE USED IN PRODUCTION

/**
 * @notice ERC7540 Implementing Controlled Async Deposits
 *
 *     This Vault has the following properties:
 *     - yield for the underlying asset is assumed to be transferred directly into the vault by some arbitrary mechanism
 *     - async deposits are subject to approval by an owner account
 *     - users can only deposit the maximum amount.
 *         To allow partial claims, the deposit and mint functions would need to allow for pro rata claims.
 *         Conversions between claimable assets/shares should be checked for rounding safety.
 */
abstract contract BaseControlledAsyncDeposits is BaseERC7540, IERC7540Deposit {
    uint256 internal _totalPendingAssets;
    mapping(address => PendingDeposit) internal _pendingDeposit;
    mapping(address => ClaimableDeposit) internal _claimableDeposit;

    struct PendingDeposit {
        uint256 assets;
    }

    struct ClaimableDeposit {
        uint256 assets;
        uint256 shares;
    }

    function totalAssets() public view override returns (uint256) {
        // total assets pending redemption must be removed from the reported total assets
        // otherwise pending assets would be treated as yield for outstanding shares
        return ERC20(asset).balanceOf(address(this)) - _totalPendingAssets;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC7540 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice this deposit request is added to any pending deposit request
    function requestDeposit(uint256 assets, address controller, address owner) external returns (uint256 requestId) {
        require(owner == msg.sender || isOperator[owner][msg.sender], "ERC7540Vault/invalid-owner");
        require(asset.balanceOf(owner) >= assets, "ERC7540Vault/insufficient-balance");
        require(assets != 0, "ZERO_ASSETS");

        SafeTransferLib.safeTransferFrom(asset, owner, address(this), assets);

        uint256 currentPendingAssets = _pendingDeposit[controller].assets;
        _pendingDeposit[controller] = PendingDeposit(assets + currentPendingAssets);

        _totalPendingAssets += assets;

        emit DepositRequest(controller, owner, REQUEST_ID, msg.sender, assets);
        return REQUEST_ID;
    }

    function pendingDepositRequest(uint256, address controller) public view returns (uint256 pendingAssets) {
        pendingAssets = _pendingDeposit[controller].assets;
    }

    function claimableDepositRequest(uint256, address controller) public view returns (uint256 claimableAssets) {
        claimableAssets = _claimableDeposit[controller].assets;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT FULFILLMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function fulfillDeposit(address controller) public onlyOwner returns (uint256 shares) {
        PendingDeposit memory request = _pendingDeposit[controller];
        require(request.assets != 0, "ZERO_ASSETS");

        shares = convertToShares(request.assets);
        _mint(address(this), shares);

        uint256 currentClaimableAssets = _claimableDeposit[controller].assets;
        uint256 currentClaimableShares = _claimableDeposit[controller].shares;
        _claimableDeposit[controller] =
            ClaimableDeposit(request.assets + currentClaimableAssets, shares + currentClaimableShares);

        delete _pendingDeposit[controller];
        _totalPendingAssets -= request.assets;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC4626 OVERRIDDEN LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver, address controller) public returns (uint256 shares) {
        require(controller == msg.sender || isOperator[controller][msg.sender], "ERC7540Vault/invalid-caller");
        require(assets != 0 && assets == maxDeposit(controller), "Must claim nonzero maximum");

        shares = _claimableDeposit[controller].shares;
        delete _claimableDeposit[controller];

        ERC20(address(this)).transfer(receiver, shares);

        emit Deposit(receiver, controller, assets, shares);
    }

    function mint(uint256 shares, address receiver, address controller) public override returns (uint256 assets) {
        require(controller == msg.sender || isOperator[controller][msg.sender], "ERC7540Vault/invalid-caller");
        require(shares != 0 && shares == maxMint(controller), "Must claim nonzero maximum");

        assets = _claimableDeposit[controller].assets;
        delete _claimableDeposit[controller];

        ERC20(address(this)).transfer(receiver, shares);

        emit Deposit(receiver, controller, assets, shares);
    }

    function maxDeposit(address controller) public view override returns (uint256) {
        return _claimableDeposit[controller].assets;
    }

    function maxMint(address controller) public view override returns (uint256) {
        return _claimableDeposit[controller].shares;
    }

    // preview functions always revert for async flows
    function previewDeposit(uint256) public pure override returns (uint256) {
        revert("ERC7540Vault/async-flow");
    }

    function previewMint(uint256) public pure override returns (uint256) {
        revert("ERC7540Vault/async-flow");
    }

    /*//////////////////////////////////////////////////////////////
                        ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC7540Deposit).interfaceId || super.supportsInterface(interfaceId);
    }
}

contract ControlledAsyncDeposits is BaseControlledAsyncDeposits {
    constructor(ERC20 _asset, string memory _name, string memory _symbol) BaseERC7540(_asset, _name, _symbol) {}
}
