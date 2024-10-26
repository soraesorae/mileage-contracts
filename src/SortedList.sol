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
    address private constant DUMMY = address(0xbeefbad);
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

    function _updateElement(address targetAddr, uint256 newValue) internal virtual {
        // delta? update_inc update_dec
        require(_alreadyParticipated[targetAddr] == true, "not found");
        require(_listLength > 0, "length = 0");
        address ptr = _head;
        address prev = DUMMY;

        while (ptr != END_OF_LIST) {
            if (ptr == targetAddr) {
                break;
            }
            prev = ptr;
            ptr = _list[ptr].next;
        }
        require(ptr != END_OF_LIST, "not found");
        if (prev == DUMMY) {
            _head = _list[ptr].next;
        } else {
            _list[prev].next = _list[ptr].next;
        }
        delete _list[ptr];
        delete _alreadyParticipated[ptr];
        --_listLength;

        _addElement(targetAddr, newValue);

        // find position after update
        // n = 1
        // if (_listLength == 1) {
        //     _list[ptr].value = newValue;
        //     return;
        // }

        // if (ptr == targetAddr) {

        // }

        // address beforePos = address(0x0);
        // address afterPos = address(0x0);

        // bool chkBeforePos = false;
        // bool chkAfterPos = false;

        // while (chkBeforePos && chkAfterPos == false) {
        //     // if ptr == EOL
        //     address next = _list[ptr].next;
        //     if (next == targetAddr) {
        //         beforePos = ptr;
        //         chkBeforePos = true;
        //     }
        //     if (_list[next].value < newValue) {
        //         afterPos = ptr;
        //         chkAfterPos = true;
        //     }
        //     ptr = next;
        // }

        // if (afterPos == beforePos) {
        //     // trivial case
        //     _list[targetAddr].value = newValue;
        // } else if (targetAddr == afterPos) {
        //     _list[targetAddr].value = newValue;
        // } else {
        //     _list[beforePos].next = _list[targetAddr].next;
        //     _list[targetAddr].next = _list[afterPos].next;
        //     _list[afterPos].next = targetAddr;
        // }
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
