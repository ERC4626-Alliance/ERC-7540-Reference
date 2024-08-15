// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC7540Vault, IERC7540Deposit, IERC7540Redeem, IERC7540Operator, IERC7540CancelDeposit, IERC7540CancelRedeem, IERC7575, IERC7741, IERC7714} from "src/interfaces/IERC7540.sol";
import {IERC165} from "src/interfaces/IERC7575.sol";
import {SafeTransferLib} from "src/libraries/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ShareToken} from "src/tokens/ShareToken.sol";

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
contract ERC7540AsyncDepositExample is IERC7540Deposit, Owned {
    /// @dev Assume requests are non-fungible and all have ID = 0
    uint256 private constant REQUEST_ID = 0;

    address public immutable asset;

    address public immutable share;
    uint8 internal immutable _shareDecimals;

    mapping(address => PendingDeposit) internal _pendingDeposit;
    mapping(address => ClaimableDeposit) internal _claimableDeposit;
    uint256 internal _totalPendingAssets;
    mapping(address => mapping(address => bool)) public isOperator;

    struct PendingDeposit {
        uint256 assets;
    }

    struct ClaimableDeposit {
        uint256 assets;
        uint256 shares;
    }

    event Deposit(address indexed owner, address indexed receiver, uint256 assets, uint256 shares);

    constructor(ERC20 _asset, string memory _name, string memory _symbol)
        Owned(msg.sender)
    {
        share = address(new ShareToken(_name, _symbol, 18));
        asset = address(_asset);
    }

    function totalAssets() public view returns (uint256) {
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
        require(ERC20(asset).balanceOf(owner) >= assets, "ERC7540Vault/insufficient-balance");
        require(assets != 0, "ZERO_ASSETS");

        SafeTransferLib.safeTransferFrom(asset, owner, address(this), assets);

        uint256 currentPendingAssets = _pendingDeposit[owner].assets;
        _pendingDeposit[owner] = PendingDeposit(assets + currentPendingAssets);

        _totalPendingAssets += assets;

        emit DepositRequest(controller, owner, REQUEST_ID, msg.sender, assets);
        return REQUEST_ID;
    }

    function pendingDepositRequest(uint256, address controller) public view returns (uint256 pendingAssets) {
        pendingAssets = _pendingDeposit[controller].assets;
    }


    /*//////////////////////////////////////////////////////////////
                        DEPOSIT FULFILLMENT LOGIC
    //////////////////////////////////////////////////////////////*/
    function fulfillDeposit(address operator) public onlyOwner returns (uint256 shares) {
        PendingDeposit memory request = _pendingDeposit[operator];

        require(request.assets != 0, "ZERO_ASSETS");

        shares = convertToShares(request.assets);
        ShareToken(share).mint(address(this), shares);

        uint256 currentClaimableAssets = _claimableDeposit[operator].assets;
        uint256 currentClaimableShares = _claimableDeposit[operator].shares;
        _claimableDeposit[operator] =
            ClaimableDeposit(request.assets + currentClaimableAssets, shares + currentClaimableShares);

        delete _pendingDeposit[operator];
        _totalPendingAssets -= request.assets;
    }

    function setOperator(address operator, bool approved) public virtual returns (bool success) {
        require(msg.sender != operator, "ERC7540Vault/cannot-set-self-as-operator");
        isOperator[msg.sender][operator] = approved;
        emit OperatorSet(msg.sender, operator, approved);
        success = true;
    }

    function claimableDepositRequest(uint256, address controller) public view returns (uint256 claimableAssets) {
        claimableAssets = _claimableDeposit[controller].assets;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC4626 OVERRIDDEN LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver, address controller) public returns (uint256 shares) {
        // The maxWithdraw call checks that assets are claimable
        require(assets != 0 && assets == maxDeposit(msg.sender), "Must claim nonzero maximum");

        shares = _claimableDeposit[msg.sender].shares;
        delete _claimableDeposit[msg.sender];

        ShareToken(share).transfer(receiver, shares);

        emit Deposit(receiver, controller, assets, shares);
    }

    function mint(uint256 shares, address receiver, address controller) public override returns (uint256 assets) {
        // The maxWithdraw call checks that shares are claimable
        require(shares != 0 && shares == maxMint(msg.sender), "Must claim nonzero maximum");

        assets = _claimableDeposit[msg.sender].assets;
        delete _claimableDeposit[msg.sender];

        ShareToken(share).transfer(receiver, shares);

        emit Deposit(receiver, controller, assets, shares);
    }

    function maxDeposit(address operator) public view returns (uint256) {
        ClaimableDeposit memory claimable = _claimableDeposit[operator];
        return claimable.assets;
    }

    function maxMint(address operator) public view returns (uint256) {
        ClaimableDeposit memory claimable = _claimableDeposit[operator];
        return claimable.shares;
    }

    // --- ERC165 support ---
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC7540Deposit).interfaceId || interfaceId == type(IERC7540Redeem).interfaceId
            || interfaceId == type(IERC7540Operator).interfaceId || interfaceId == type(IERC7540CancelDeposit).interfaceId
            || interfaceId == type(IERC7540CancelRedeem).interfaceId || interfaceId == type(IERC7575).interfaceId
            || interfaceId == type(IERC7741).interfaceId || interfaceId == type(IERC7714).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    // Preview functions always revert for async flows

    function previewDeposit(uint256) public pure returns (uint256) {
        revert();
    }

    function previewMint(uint256) public pure returns (uint256) {
        revert();
    }

    function convertToShares(uint256 assets) public pure returns (uint256) {
        return assets;
    }
}
