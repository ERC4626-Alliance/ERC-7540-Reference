// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

import {IERC4626} from "./IERC4626.sol";

interface IERC7540 is IERC4626 {

    event Request(address indexed sender, address indexed receiver, uint8 indexed RequestType, uint256 assets, uint256 shares);

    // Required
    function ownerOf(uint256 rid);

    function claimRequest(uint256 rid, address receiver, RequestType requestType);

    function transferRequest(uint256 rid, address receiver, RequestType requestType);

    function request(uint256 assets, uint256 shares, address receiver, RequestType requestType) external returns (uint256 rid);

    function viewRequest(uint256 rid, RequestType requestType) external view returns (uint256 pendingAssets, uint256 pendingShares, uint256 claimableAssets, uint256 claimableShares);

}
