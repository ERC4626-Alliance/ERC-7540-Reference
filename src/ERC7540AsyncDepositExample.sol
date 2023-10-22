// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "solmate/mixins/ERC4626.sol";
import "solmate/auth/Owned.sol";

// THIS VAULT IS AN UNOPTIMIZED, POTENTIALLY UNSECURE REFERENCE EXAMPLE AND IN NO WAY MEANT TO BE USED IN PRODUCTION


/** 
@notice ERC7540 Implementing Controlled Async Deposits 

    This Vault has the following properties:
    - yield for the underlying asset is assumed to be transferred directly into the vault by some arbitrary mechanism
    - async deposits are subject to approval by an owner account
    - users can only deposit the maximum amount. 
        To allow partial claims, the deposit and mint functions would need to allow for pro rata claims. 
        Conversions between claimable assets/shares should be checked for rounding safety.
*/
contract ERC7540AsyncDepositExample is ERC4626, Owned {
    using SafeTransferLib for ERC20;

    mapping(address => DepositRequest) internal _pendingDeposit;
    uint256 internal _totalPendingAssets;

    struct DepositRequest {
        uint256 assets;
        uint256 shares;
        uint32 claimableTimestamp;
    }

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset, _name, _symbol) Owned(msg.sender) {}

    function totalAssets() public view override returns (uint256) {
        // total assets pending redemption must be removed from the reported total assets
        // otherwise pending assets would be treated as yield for outstanding shares
        return asset.balanceOf(address(this)) - _totalPendingAssets;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC7540 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice TODO
    function requestDeposit(uint256 assets, address operator) public {
        require(assets != 0, "ZERO_ASSETS");

        asset.safeTransferFrom(msg.sender, address(this), assets);

        // TODO
    }

    function pendingDepositRequest(address operator) public view returns (uint256 shares) {
        // TODO
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT FULFILLMENT LOGIC
    //////////////////////////////////////////////////////////////*/
    function fulfillDeposit(address operator) public onlyOwner {
        // TODO
    }

    /*//////////////////////////////////////////////////////////////
                        ERC4626 OVERRIDDEN LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(
        uint256 assets,
        address receiver
    ) public override returns (uint256 shares) {
        // TODO
    }

    function mint(
        uint256 shares,
        address receiver
    ) public override returns (uint256 assets) {
        // TODO
    }

    function maxDeposit(address operator) public view override returns (uint256) {
        // TODO
    }

    function maxMint(address operator) public view override returns (uint256) {
        // TODO
    }

    // Preview functions always revert for async flows

    function previewDeposit(uint256) public view override returns (uint256) {
        revert ();
    }

    function previewMint(uint256) public view override returns (uint256) {
        revert ();
    }

}