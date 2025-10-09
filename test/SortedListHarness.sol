// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SortedList} from "../src/SortedList.sol";
import {ISortedList} from "../src/ISortedList.sol";

contract SortedListHarness is SortedList {
    function update(address addr, uint256 value) public {
        _updateElement(addr, value);
    }

    function getAll() public view returns (ISortedList.DataPair[] memory) {
        return abi.decode(_getAllElement(), (ISortedList.DataPair[]));
    }

    function getRange(uint256 from, uint256 to) public view returns (ISortedList.DataPair[] memory) {
        return abi.decode(_getElementRange(from, to), (ISortedList.DataPair[]));
    }

    function indexOf(
        address account
    ) public view returns (int256) {
        return _getElementIndex(account);
    }

    function remove(
        address target
    ) public {
        _removeElement(target, true);
    }

    function push(address addr, uint256 value) public {
        _push(addr, value);
    }

    function pop() public {
        _pop();
    }

    function contains(
        address addr
    ) public view returns (bool) {
        return _getElementIndex(addr) >= 0;
    }

    function valueOf(
        address addr
    ) public view returns (uint256) {
        ISortedList.DataPair[] memory elements = getAll();
        for (uint256 i = 0; i < elements.length; i++) {
            if (elements[i].addr == addr) {
                return elements[i].value;
            }
        }
        revert("Element not found");
    }

    function head() public view returns (address) {
        ISortedList.DataPair[] memory elements = getAll();
        if (elements.length == 0) return address(0);
        return elements[0].addr;
    }

    function tail() public view returns (address) {
        ISortedList.DataPair[] memory elements = getAll();
        if (elements.length == 0) return address(0);
        return elements[elements.length - 1].addr;
    }
}
