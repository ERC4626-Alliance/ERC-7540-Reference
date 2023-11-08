// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC165} from "./IERC165.sol";

interface IERC7540Redeem is IERC165 {
    event RedeemRequest(address indexed sender, address indexed operator, address indexed owner, uint256 shares);

    /**
     * @dev Assumes control of shares from owner and submits a Request for asynchronous redeem/withdraw.
     *
     * - MUST support a redeem Request flow where the control of shares is taken from owner directly
     *   where msg.sender has ERC-20 approval over the shares of owner.
     * - MUST revert if all of shares cannot be requested for redeem / withdraw.
     */
    function requestRedeem(uint256 shares, address operator, address owner) external;

    /**
     * @dev Returns the amount of requested shares in Pending state for the operator to redeem or withdraw.
     *
     * - MUST NOT include any shares in Claimable state for redeem or withdraw.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT revert unless due to integer overflow caused by an unreasonably large input.
     */
    function pendingRedeemRequest(address operator) external view returns (uint256 shares);
}
