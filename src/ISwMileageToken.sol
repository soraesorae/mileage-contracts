// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISwMileageToken {
    struct Student {
        address wallet;
        uint256 balance;
    }

    function rankingRange(uint256 from, uint256 to) external view returns (Student[] memory);
}
