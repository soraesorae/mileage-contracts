// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Pausable} from "kaia-contracts/contracts/security/Pausable.sol";
import {Context} from "kaia-contracts/contracts/utils/Context.sol";

// References
// - kaia-contracts/contracts/access/Ownable.sol
// - kaia-contracts/contracts/access/AccessControl.sol
abstract contract Admin is Context {
    mapping(address => bool) private _admin;

    event AddAdministrator(address indexed account);
    event RemoveAdministrator(address indexed account);

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
            emit AddAdministrator(account);
        }
    }

    function _removeAdmin(
        address account
    ) internal virtual {
        if (_admin[account]) {
            _admin[account] = false;
            emit RemoveAdministrator(account);
        }
    }
}
