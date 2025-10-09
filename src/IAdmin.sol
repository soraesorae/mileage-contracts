// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// References
// - kaia-contracts/contracts/access/Ownable.sol
// - kaia-contracts/contracts/access/AccessControl.sol
interface IAdmin {
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

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
