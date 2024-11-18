// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SortedList} from "../src/SortedList.sol";
import {BubbleSort} from "./utils/BubbleSort.sol";

contract MockSortedList is SortedList {
    function addElement(address addr, uint256 value) public {
        // _addElement(addr, value);
        _updateElement(addr, value);
    }

    function updateElement(address targetAddr, uint256 newValue) public {
        _updateElement(targetAddr, newValue);
    }

    function getAllElement() public view returns (DataPair[] memory) {
        return abi.decode(_getAllElement(), (DataPair[]));
    }

    function getElementRange(uint256 from, uint256 to) public view returns (bytes memory) {
        return _getElementRange(from, to);
    }
}
