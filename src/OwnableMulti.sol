// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Pausable} from "kaia-contracts/contracts/security/Pausable.sol";
import {Context} from "kaia-contracts/contracts/utils/Context.sol";

// reference: kaia-contracts/contracts/access/Ownable.sol
abstract contract OwnableMulti is Context {
    mapping(address => bool) public owner;

    event OwnershipAdded(address indexed newOwner);
    event OwnershipRemoved(address indexed target);

    constructor() {
        _addOwnership(_msgSender());
    }

    function isOwner(address _addr) public view returns (bool) {
        return owner[_addr];
    }

    modifier onlyOwner() {
        require(isOwner(_msgSender()), "caller is not the owner");
        _;
    }

    function addOwnership(address newOwner) public virtual onlyOwner {
        _addOwnership(newOwner);
    }

    function removeOwnership(address target) public virtual onlyOwner {
        _removeOwnership(target);
    }

    function _addOwnership(address newOwner) internal virtual {
        owner[newOwner] = true;
        emit OwnershipAdded(newOwner);
    }

    // delete vs false

    function _removeOwnership(address target) internal virtual {
        delete owner[target];
        emit OwnershipRemoved(target);
    }
}
