// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SortedList} from "../src/SortedList.sol";
import {ISortedList} from "../src/ISortedList.sol";

contract SortedListHarness is SortedList {
    function update(address addr, uint256 value) public {
        _updateElement(addr, value);
    }

    function getAll() public view returns (ISortedList.DataPair[] memory) {
        ISortedList.DataPair[] memory result = new ISortedList.DataPair[](_getListLength());
        address current = _head;
        for (uint256 i = 0; i < _getListLength(); i++) {
            result[i] = ISortedList.DataPair({addr: current, value: _list[current].value});
            current = _list[current].next;
        }
        return result;
    }

    function getRange(uint256 from, uint256 to) public view returns (ISortedList.DataPair[] memory) {
        return abi.decode(_getElementRange(from, to), (ISortedList.DataPair[]));
    }

    function indexOf(
        address account
    ) public view returns (int256) {
        if (!_participated[account]) {
            return -1;
        }
        address current = _head;
        int256 index = 1;
        while (current != END_OF_LIST) {
            if (current == account) {
                return index;
            }
            current = _list[current].next;
            index++;
        }
        return -1;
    }

    function remove(
        address target
    ) public {
        _removeElement(target, true);
    }

    function push(address addr, uint256 value) public {
        require(_participated[addr] == false, "address exists");
        _list[addr] = ISortedList.Node({next: _head, value: value});
        _head = addr;
        _participated[addr] = true;
        ++_listLength;
    }

    function pop() public {
        require(_head != END_OF_LIST, "list is empty");
        address next = _list[_head].next;
        _participated[_head] = false;
        delete _list[_head];
        _head = next;
        --_listLength;
    }

    function contains(
        address addr
    ) public view returns (bool) {
        return indexOf(addr) >= 0;
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
