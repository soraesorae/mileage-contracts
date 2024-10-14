// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {KIP7} from "kaia-contracts/contracts/KIP/token/KIP7/KIP7.sol";

contract SwMaileageToken is KIP7 {
    constructor() KIP7("SwMileageToken", "SMT") {}
}