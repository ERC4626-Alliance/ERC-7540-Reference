// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {BaseERC7540} from "src/BaseERC7540.sol";
import {IERC7540Deposit} from "src/interfaces/IERC7540.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

// THIS VAULT IS AN UNOPTIMIZED, POTENTIALLY UNSECURE REFERENCE EXAMPLE AND IN NO WAY MEANT TO BE USED IN PRODUCTION

/**
 * @notice ERC7540 Implementing Controlled Async Deposits
 *
 *     This Vault has the following properties:
 *     - yield for the underlying asset is assumed to be transferred directly into the vault by some arbitrary mechanism
 *     - async deposits are subject to approval by an owner account
 */
abstract contract BaseControlledAsyncDeposit is BaseERC7540, IERC7540Deposit {
    using FixedPointMathLib for uint256;

    uint256 internal _totalPendingDepositAssets;
    mapping(address => PendingDeposit) internal _pendingDeposit;
    mapping(address => ClaimableDeposit) internal _claimableDeposit;

    struct PendingDeposit {
        uint256 assets;
    }

    struct ClaimableDeposit {
        uint256 assets;
        uint256 shares;
    }

    function totalAssets() public view virtual override returns (uint256) {
        // total assets pending redemption must be removed from the reported total assets
        // otherwise pending assets would be treated as yield for outstanding shares
        return ERC20(asset).balanceOf(address(this)) - _totalPendingDepositAssets;
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

        _totalPendingDepositAssets += assets;

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

    function fulfillDeposit(address controller, uint256 assets) public onlyOwner returns (uint256 shares) {
        PendingDeposit storage request = _pendingDeposit[controller];
        require(request.assets != 0 && assets <= request.assets, "ZERO_ASSETS");

        shares = convertToShares(assets);
        _mint(address(this), shares);

        _claimableDeposit[controller] = ClaimableDeposit(
            _claimableDeposit[controller].assets + assets, _claimableDeposit[controller].shares + shares
        );

        request.assets -= assets;
        _totalPendingDepositAssets -= assets;
    }

    function deposit(uint256 assets, address receiver, address controller) public returns (uint256 shares) {
        require(controller == msg.sender || isOperator[controller][msg.sender], "ERC7540Vault/invalid-caller");
        require(assets != 0, "Must claim nonzero amount");

        // Claiming partially introduces precision loss. The user therefore receives a rounded down amount,
        // while the claimable balance is reduced by a rounded up amount.
        ClaimableDeposit storage claimable = _claimableDeposit[controller];
        shares = assets.mulDivDown(claimable.shares, claimable.assets);
        uint256 sharesUp = assets.mulDivUp(claimable.shares, claimable.assets);

        claimable.assets -= assets;
        claimable.shares = claimable.shares > sharesUp ? claimable.shares - sharesUp : 0;

        ERC20(address(this)).transfer(receiver, shares);

        emit Deposit(receiver, controller, assets, shares);
    }

    function mint(uint256 shares, address receiver, address controller) public override returns (uint256 assets) {
        require(controller == msg.sender || isOperator[controller][msg.sender], "ERC7540Vault/invalid-caller");
        require(shares != 0, "Must claim nonzero amount");

        // Claiming partially introduces precision loss. The user therefore receives a rounded down amount,
        // while the claimable balance is reduced by a rounded up amount.
        ClaimableDeposit storage claimable = _claimableDeposit[controller];
        assets = shares.mulDivDown(claimable.assets, claimable.shares);
        uint256 assetsUp = shares.mulDivUp(claimable.assets, claimable.shares);

        claimable.assets = claimable.assets > assetsUp ? claimable.assets - assetsUp : 0;
        claimable.shares -= shares;

        ERC20(address(this)).transfer(receiver, shares);

        emit Deposit(receiver, controller, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                        ERC4626 OVERRIDDEN LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        shares = deposit(assets, receiver, receiver);
    }

    function mint(uint256 shares, address receiver) public virtual override returns (uint256 assets) {
        assets = mint(shares, receiver, receiver);
    }

    function maxDeposit(address controller) public view virtual override returns (uint256) {
        return _claimableDeposit[controller].assets;
    }

    function maxMint(address controller) public view virtual override returns (uint256) {
        return _claimableDeposit[controller].shares;
    }

    function previewDeposit(uint256) public pure virtual override returns (uint256) {
        revert("ERC7540Vault/async-flow");
    }

    function previewMint(uint256) public pure virtual override returns (uint256) {
        revert("ERC7540Vault/async-flow");
    }

    /*//////////////////////////////////////////////////////////////
                        ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(IERC7540Deposit).interfaceId || super.supportsInterface(interfaceId);
    }
}

contract ControlledAsyncDeposit is BaseControlledAsyncDeposit {
    constructor(ERC20 _asset, string memory _name, string memory _symbol) BaseERC7540(_asset, _name, _symbol) {}
}
