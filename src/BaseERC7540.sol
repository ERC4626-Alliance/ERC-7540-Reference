// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC7540Operator} from "src/interfaces/IERC7540.sol";
import {IERC7575} from "src/interfaces/IERC7575.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {IERC165} from "src/interfaces/IERC7575.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

abstract contract BaseERC7540 is ERC4626, Owned, IERC7540Operator {
    /// @dev Assume requests are non-fungible and all have ID = 0
    uint256 internal constant REQUEST_ID = 0;

    address public share = address(this);

    mapping(address => mapping(address => bool)) public isOperator;

    constructor(ERC20 _asset, string memory _name, string memory _symbol)
        Owned(msg.sender)
        ERC4626(_asset, _name, _symbol)
    {}

    /*//////////////////////////////////////////////////////////////
                        ERC7540 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOperator(address operator, bool approved) public virtual returns (bool success) {
        require(msg.sender != operator, "ERC7540Vault/cannot-set-self-as-operator");
        isOperator[msg.sender][operator] = approved;
        emit OperatorSet(msg.sender, operator, approved);
        success = true;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return interfaceId == type(IERC7575).interfaceId || interfaceId == type(IERC7540Operator).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }
}
