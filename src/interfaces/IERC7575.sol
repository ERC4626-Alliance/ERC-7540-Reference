// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

interface IERC7575MinimalVault {

    function asset() external returns(address);

    function share() external returns (address);

    function convertToShares(uint256 assets) external pure returns (uint256 shares);

    function convertToAssets(uint256 shares) external pure returns (uint256 assets);

    function totalAssets() external view returns (uint256);
}

interface IERC7575DepositVault {
    function deposit(uint256 assets, address receiver) external payable returns (uint256 shares);
    
    function previewDeposit(uint256 assets) external pure returns (uint256 shares);
    
    function maxDeposit(address owner) external pure returns (uint256);
}

interface IERC7575MintVault {
    function mint(uint256 shares, address receiver) external payable returns (uint256 assets);
    
    function previewMint(uint256 shares) external pure returns (uint256 assets);
    
    function maxMint(address owner) external pure returns (uint256);
}

interface IERC7575RedeemVault {
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    function previewRedeem(uint256 shares) external pure returns (uint256 assets);

    function maxRedeem(address owner) external view returns (uint256);
}

interface IERC7575WithdrawVault {
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    function previewWithdraw(uint256 assets) external pure returns (uint256 shares);

    function maxWithdraw(address owner) external view returns (uint256);
}

interface IERC7575 {

    function asset() external returns(address);

    function share() external returns (address);

    function convertToShares(uint256 assets) external pure returns (uint256 shares);

    function convertToAssets(uint256 shares) external pure returns (uint256 assets);

    function totalAssets() external view returns (uint256);

    function deposit(uint256 assets, address receiver) external payable returns (uint256 shares);
    
    function previewDeposit(uint256 assets) external pure returns (uint256 shares);
    
    function maxDeposit(address owner) external pure returns (uint256);

    function mint(uint256 shares, address receiver) external payable returns (uint256 assets);
    
    function previewMint(uint256 shares) external pure returns (uint256 assets);
    
    function maxMint(address owner) external pure returns (uint256);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    function previewRedeem(uint256 shares) external pure returns (uint256 assets);

    function maxRedeem(address owner) external view returns (uint256);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    function previewWithdraw(uint256 assets) external pure returns (uint256 shares);

    function maxWithdraw(address owner) external view returns (uint256);
}