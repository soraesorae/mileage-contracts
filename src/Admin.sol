// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Context} from "kaia-contracts/contracts/utils/Context.sol";
import {IAdmin} from "./IAdmin.sol";

// References
// - kaia-contracts/contracts/access/Ownable.sol
// - kaia-contracts/contracts/access/AccessControl.sol
abstract contract Admin is Context, IAdmin {
    mapping(address => bool) private _admin;

    constructor() {
        _addAdmin(_msgSender());
    }

    function isAdmin(
        address account
    ) public view returns (bool) {
        return _admin[account];
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "caller is not the admin");
        _;
    }

    function addAdmin(
        address account
    ) public virtual onlyAdmin {
        _addAdmin(account);
    }

    function removeAdmin(
        address account
    ) public virtual onlyAdmin {
        _removeAdmin(account);
    }

    // grant
    function _addAdmin(
        address account
    ) internal virtual {
        if (!_admin[account]) {
            _admin[account] = true;
            emit AdminAdded(account);
        }
    }

    function _removeAdmin(
        address account
    ) internal virtual {
        if (_admin[account]) {
            _admin[account] = false;
            emit AdminRemoved(account);
        }
    }
}
