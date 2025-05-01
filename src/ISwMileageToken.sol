// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IKIP7} from "kaia-contracts/contracts/KIP/token/KIP7/IKIP7.sol";
import {IKIP7Burnable} from "kaia-contracts/contracts/KIP/token/KIP7/extensions/IKIP7Burnable.sol";

interface ISwMileageToken is IKIP7, IKIP7Burnable {
    struct Student {
        address account;
        uint256 balance;
    }

    function mint(address account, uint256 amount) external;
    function getRankingRange(uint256 from, uint256 to) external view returns (Student[] memory);
}
