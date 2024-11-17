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
    mapping(address => bool) private _participated;

    address private constant END_OF_LIST = address(0xdeadbeef);
    address private constant DUMMY = address(0x0badbeef);
    address private _head = END_OF_LIST;

    uint256 private _listLength = 0;

    event UpdateElement(address indexed addr, uint256 prev, uint256 value);
    event RemoveElement(address indexed addr);

    constructor() {}

    function _getListLength() internal view virtual returns (uint256) {
        return _listLength;
    }

    // alreadyparticipated or participted already
    // function _isAlready

    /// @dev naive sorting solution

    function _addElement(address addr, uint256 value) private {
        require(_participated[addr] == false, "duplicated");
        _participated[addr] = true;
        if (_listLength == 0) {
            _list[addr] = Node(END_OF_LIST, value);
            _head = addr;
        } else {
            address ptr = _head;

            if (_list[ptr].value < value) {
                _list[addr] = Node(ptr, value);
                _head = addr;
            } else {
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
        }
        ++_listLength;
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

    /// @dev return (address, value)[] ranking [from, to]
    function _getElementRange(uint256 from, uint256 to) internal view virtual returns (bytes memory) {
        require(to >= from, "to < from");
        require(from > 0, "from == 0");
        if (to > _listLength) {
            to = _listLength;
        }
        address ptr = _head;
        uint256 listIndex = 1;
        uint256 outputIndex = 0;
        DataPair[] memory output = new DataPair[](to - from + 1);
        while (ptr != END_OF_LIST) {
            if (from <= listIndex) {
                output[outputIndex] = DataPair(ptr, _list[ptr].value);
                ++outputIndex;
                if (listIndex >= to) {
                    break;
                }
            }
            ptr = _list[ptr].next;
            ++listIndex;
        }
        require(outputIndex == output.length, "something wrong");
        return abi.encode(output);
    }

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

    function _updateElement(address target, uint256 newValue) internal virtual {
        // delta? update_inc update_dec
        // require(_participated[targetAddr] == true, "not found");
        // require(_listLength > 0, "length = 0");
        uint256 prevValue = 0;
        if (_participated[target]) {
            address ptr = _head;
            address prev = DUMMY;

            while (ptr != END_OF_LIST) {
                if (ptr == target) {
                    break;
                }
                prev = ptr;
                ptr = _list[ptr].next;
            }
            require(ptr != END_OF_LIST, "not found");
            prevValue = _list[ptr].value;
            if (prev == DUMMY) {
                _head = _list[ptr].next;
            } else {
                _list[prev].next = _list[ptr].next;
            }
            delete _list[ptr];
            _participated[ptr] = false;
            --_listLength;
        }
        _addElement(target, newValue);
        emit UpdateElement(target, prevValue, newValue);
    }

    function _removeElement(address target) internal {
        require(_participated[target] != false, "not found in the list");
        require(_listLength > 0, "length = 0");

        address ptr = _head;

        while (ptr != END_OF_LIST) {
            if (ptr == target) {
                break;
            }
            ptr = _list[ptr].next;
        }
        require(ptr != END_OF_LIST, "not found");
        _head = _list[ptr].next;
        delete _list[ptr];
        _participated[ptr] = false;
        --_listLength;

        emit RemoveElement(target);
    }
}
