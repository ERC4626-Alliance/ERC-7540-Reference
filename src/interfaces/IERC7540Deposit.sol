// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC165} from "./IERC165.sol";

interface IERC7540Deposit is IERC165 {
    event DepositRequest(address indexed sender, address indexed operator, uint256 assets);

    /**
     * @dev Transfers assets from msg.sender into the Vault and submits a Request for asynchronous deposit/mint.
     *
     * - MUST support ERC-20 approve / transferFrom on asset as a deposit Request flow.
     * - MUST revert if all of assets cannot be requested for deposit/mint.
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault's underlying asset token.
     */
    function requestDeposit(uint256 assets, address operator) external;

    /**
     * @dev Returns the amount of requested assets in Pending state for the operator to deposit or mint.
     *
     * - MUST NOT include any assets in Claimable state for deposit or mint.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT revert unless due to integer overflow caused by an unreasonably large input.
     */
    function pendingDepositRequest(address operator) external view returns (uint256 assets);
}
