// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {ISortedList} from "./ISortedList.sol";

abstract contract SortedList is ISortedList {
    mapping(address => Node) internal _list;
    mapping(address => bool) internal _participated;

    address internal constant END_OF_LIST = address(0xdeadbeef);
    address internal constant DUMMY = address(0x0badbeef);
    address internal constant NOT_FOUND = address(0x04040404);
    address internal _head = END_OF_LIST;

    uint256 internal _listLength = 0;

    constructor() {}

    function getListLength() public view virtual returns (uint256) {
        return _getListLength();
    }

    function _getListLength() internal view virtual returns (uint256) {
        return _listLength;
    }

    function participated(
        address addr
    ) public view virtual returns (bool) {
        return _participated[addr];
    }

    function _getElementRange(
        uint256 from,
        uint256 to
    ) internal view virtual returns (bytes memory) {
        if (from == 0) revert InvalidRangeFrom();
        if (from > to) revert InvalidRangeTo(from, to);

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

    function _updateElement(
        address target,
        uint256 newValue
    ) internal virtual {
        uint256 prevValue = 0;

        if (_participated[target]) {
            prevValue = _list[target].value;
            _removeElement(target, false);
        }

        _insertElement(target, newValue);

        emit UpdateElement(target, prevValue, newValue);
    }

    function _insertElement(
        address addr,
        uint256 value
    ) internal virtual {
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

    function _removeElement(
        address target,
        bool _event
    ) internal {
        if (!_participated[target]) revert AddressNotInList(target);
        if (_listLength == 0) revert ListIsEmpty();

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
