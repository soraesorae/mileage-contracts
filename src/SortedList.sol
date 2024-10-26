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
    mapping(address => bool) private _alreadyParticipated;

    address private constant END_OF_LIST = address(0xbadbeef);
    address private _head = END_OF_LIST;

    uint256 private _listLength = 0;

    constructor() {}

    function _getListLength() internal view virtual returns (uint256) {
        return _listLength;
    }

    /// @dev naive sorting solution

    function _addElement(address addr, uint256 value) internal virtual {
        require(_alreadyParticipated[addr] == false, "duplicated");
        _alreadyParticipated[addr] = true;
        if (_listLength == 0) {
            _list[addr] = Node(END_OF_LIST, value);
            _head = addr;
        } else {
            address ptr = _head;

            if (_list[ptr].value < value) {
                _list[addr] = Node(ptr, value);
                _head = addr;
                ++_listLength;
                return;
            }
            while (true) {
                address next_node = _list[ptr].next;
                if (next_node == END_OF_LIST || _list[next_node].value < value) {
                    _list[addr] = Node(next_node, value);
                    _list[ptr].next = addr;
                    break;
                }
                ptr = next_node;
            }
        }
        ++_listLength;
        return;
    }

    function _getAllElement() internal view virtual returns (bytes memory) {
        address ptr = _head;
        DataPair[] memory arr = new DataPair[](_listLength);
        uint256 i = 0;
        while (ptr != END_OF_LIST) {
            arr[i] = DataPair(ptr, _list[ptr].value);
            ptr = _list[ptr].next;
            ++i;
        }
        return abi.encode(arr);
    }
}
