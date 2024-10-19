// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

abstract contract SortedList {
    struct Node {
        address next;
        uint256 value;
    }

    struct DataPair {
        address addr;
        uint256 value;
    }

    mapping(address => Node) private _list;
    mapping(address => bool) private _already_participated;

    address private constant END_OF_LIST = address(0xbadbeef);
    address private _head = END_OF_LIST;

    uint256 private _list_length = 0;

    constructor() {}

    function _getListLength() internal view virtual returns (uint256) {
        return _list_length;
    }

    /// @dev naive sorting solution

    function _addElement(address addr, uint256 value) internal virtual {
        require(_already_participated[addr] == false, "duplicated");
        _already_participated[addr] = true;
        if (_list_length == 0) {
            _list[addr] = Node(END_OF_LIST, value);
            _head = addr;
        } else {
            address ptr = _head;

            if (value <= _list[ptr].value) {
                _list[addr] = Node(ptr, value);
                _head = addr;
                ++_list_length;
                return;
            }
            while (true) {
                address next_node = _list[ptr].next;
                if (next_node == END_OF_LIST || value <= _list[next_node].value) {
                    _list[addr] = Node(next_node, value);
                    _list[ptr].next = addr;
                    break;
                }
                ptr = next_node;
            }
        }
        ++_list_length;
        return;
    }

    function _getAllElement() internal view virtual returns (DataPair[] memory) {
        address ptr = _head;
        DataPair[] memory arr = new DataPair[](_list_length);
        uint256 i = 0;
        while (ptr != END_OF_LIST) {
            arr[i] = DataPair(ptr, _list[ptr].value);
            ptr = _list[ptr].next;
            ++i;
        }
        return arr;
    }
}
