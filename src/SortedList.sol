// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {ISortedList} from "./ISortedList.sol";

abstract contract SortedList is ISortedList {
    mapping(address => Node) private _list;
    mapping(address => bool) private _participated;

    address private constant END_OF_LIST = address(0xdeadbeef);
    address private constant DUMMY = address(0x0badbeef);
    address private constant NOT_FOUND = address(0x04040404);
    address private _head = END_OF_LIST;

    uint256 private _listLength = 0;

    constructor() {}

    function getListLength() public view virtual returns (uint256) {
        return _getListLength();
    }

    function _getListLength() internal view virtual returns (uint256) {
        return _listLength;
    }

    // util function for testing
    // Use this function only for testing
    function _push(address addr, uint256 value) internal virtual {
        require(_participated[addr] == false, "address already exists");

        _list[addr] = Node({next: _head, value: value});
        _head = addr;
        _participated[addr] = true;
        ++_listLength;
    }

    // Use this function only for testing
    function _pop() internal virtual {
        require(_head != END_OF_LIST, "empty list");

        address next = _list[_head].next;
        _participated[_head] = false;
        delete _list[_head];
        _head = next;
        --_listLength;
    }

    // Use this function only for testing
    function _getElementIndex(
        address account
    ) internal view virtual returns (int256) {
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

    // Use this function only for testing
    function _getAllElement() internal view virtual returns (bytes memory) {
        DataPair[] memory result = new DataPair[](_listLength);

        address current = _head;
        for (uint256 i = 0; i < _listLength; i++) {
            result[i] = DataPair({addr: current, value: _list[current].value});
            current = _list[current].next;
        }

        return abi.encode(result);
    }

    function _getElementRange(uint256 from, uint256 to) internal view virtual returns (bytes memory) {
        require(from > 0, "from == 0");
        require(from <= to, "to < from");

        if (from > _listLength) {
            DataPair[] memory empty;
            return abi.encode(empty);
        }

        to = to > _listLength ? _listLength : to;
        uint256 length = to - from + 1;
        DataPair[] memory result = new DataPair[](length);

        address current = _head;
        for (uint256 i = 1; i < from; i++) {
            current = _list[current].next;
        }

        for (uint256 i = 0; i < length; i++) {
            result[i] = DataPair({addr: current, value: _list[current].value});
            current = _list[current].next;
        }

        return abi.encode(result);
    }

    function _updateElement(address target, uint256 newValue) internal virtual {
        uint256 prevValue = 0;

        if (_participated[target]) {
            prevValue = _list[target].value;
            _removeElement(target, false);
        }

        _insertElement(target, newValue);

        emit UpdateElement(target, prevValue, newValue);
    }

    function _insertElement(address addr, uint256 value) internal virtual {
        address ptr = _head;
        address prev = DUMMY;

        while (ptr != END_OF_LIST && _list[ptr].value >= value) {
            prev = ptr;
            ptr = _list[ptr].next;
        }

        if (prev == DUMMY) {
            _list[addr] = Node({next: _head, value: value});
            _head = addr;
        } else {
            _list[addr] = Node({next: _list[prev].next, value: value});
            _list[prev].next = addr;
        }

        _participated[addr] = true;
        ++_listLength;
    }

    function _removeElement(address target, bool _event) internal {
        require(_participated[target], "not found in the list");
        require(_listLength > 0, "length = 0");

        address ptr = _head;
        address prev = DUMMY;

        while (ptr != END_OF_LIST) {
            if (ptr == target) {
                break;
            }
            prev = ptr;
            ptr = _list[ptr].next;
        }

        if (prev == DUMMY) {
            _head = _list[ptr].next;
        } else {
            _list[prev].next = _list[ptr].next;
        }

        delete _list[ptr];
        _participated[ptr] = false;
        --_listLength;
        if (_event) {
            emit RemoveElement(target);
        }
    }
}
