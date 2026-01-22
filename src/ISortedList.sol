// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface ISortedList {
    error InvalidRangeFrom();
    error InvalidRangeTo(uint256 from, uint256 to);
    error AddressNotInList(address target);
    error ListIsEmpty();
    struct Node {
        address next;
        uint256 value;
    }

    struct DataPair {
        address addr;
        uint256 value;
    }

    event UpdateElement(address indexed account, uint256 indexed prev, uint256 indexed value);
    event RemoveElement(address indexed account);
}
