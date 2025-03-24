// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Pausable} from "kaia-contracts/contracts/security/Pausable.sol";
import {Context} from "kaia-contracts/contracts/utils/Context.sol";

// References
// - kaia-contracts/contracts/access/Ownable.sol
// - kaia-contracts/contracts/access/AccessControl.sol
interface IAdmin {
    function isAdmin(
        address account
    ) external view returns (bool);

    function addAdmin(
        address account
    ) external;

    function removeAdmin(
        address account
    ) external;
}
