// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SortedList} from "../src/SortedList.sol";
import {BubbleSort} from "./utils/BubbleSort.sol";

contract MockSortedList is SortedList {
    function getListLength() public view returns (uint256) {
        return _getListLength();
    }

    function addElement(address addr, uint256 value) public {
        _addElement(addr, value);
    }

    function updateElement(address targetAddr, uint256 newValue) public {
        _updateElement(targetAddr, newValue);
    }

    function getAllElement() public view returns (bytes memory) {
        return _getAllElement();
    }

    function getElementRange(uint256 from, uint256 to) public view returns (bytes memory) {
        return _getElementRange(from, to);
    }
}
