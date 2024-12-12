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
    address private constant NOT_FOUND = address(0x04040404);
    address private _head = END_OF_LIST;

    uint256 private _listLength = 0;

    event UpdateElement(address indexed addr, uint256 prev, uint256 value);
    event RemoveElement(address indexed addr);

    constructor() {}

    function getListLength() public view virtual returns (uint256) {
        return _getListLength();
    }

    function _getListLength() internal view virtual returns (uint256) {
        return _listLength;
    }

    // function getListNode() internal returns (Node memory) {}

    function _push(address addr, uint256 value) internal virtual {
        require(_participated[addr] == false);
        _list[addr] = Node({next: _head, value: value});
        _head = addr;
        _participated[addr] = true;
        ++_listLength;
    }

    function _pop() internal virtual {
        require(_head != END_OF_LIST);
        address next = _list[_head].next;
        _participated[_head] = false;
        delete _list[_head];
        _head = next;
        --_listLength;
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
        require(from > 0, "from == 0");
        require(from <= to, "to < from");
        if (from > _listLength) {
            DataPair[] memory empty;
            return abi.encode(empty);
        }
        if (to > _listLength) {
            to = _listLength;
        }
        if (from > to) {
            DataPair[] memory empty;
            return abi.encode(empty);
        }
        address ptr = _head;
        uint256 listIndex = 1;
        uint256 outputIndex = 0;
        DataPair[] memory output = new DataPair[](to + 1 - from); // to avoid overflow
        while (ptr != END_OF_LIST) {
            if (from <= listIndex) {
                output[outputIndex] = DataPair({addr: ptr, value: _list[ptr].value});
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

    function _getElementIndex(
        address account
    ) internal virtual returns (int256) {
        address ptr = _head;
        int256 i = 1;
        while (ptr != END_OF_LIST) {
            if (ptr == account) {
                return i;
            }
            ++i;
        }
        return -1;
    }

    // check sort

    // event Log(address indexed target, uint256 indexed value, address indexed next, address h);

    // function check() private {
    //     address ptr = _head;
    //     DataPair[] memory arr = new DataPair[](_listLength);
    //     uint256 i = 0;
    //     while (ptr != END_OF_LIST) {
    //         emit Log(ptr, _list[ptr].value, _list[ptr].next, _head);
    //         arr[i] = DataPair(ptr, _list[ptr].value);
    //         ptr = _list[ptr].next;
    //         ++i;
    //     }
    // }

    function _updateElement(address target, uint256 newValue) internal virtual {
        uint256 prevValue = 0;
        if (_participated[target]) {
            // y <- x: between y and x
            address ptr = _head;
            address prev = DUMMY;
            address currentPos = NOT_FOUND; // .. <- [target] <- [currentPos] <- ..
            address nextPos = NOT_FOUND; // .. <- [here] <- [nextPos] <- ..

            while (ptr != END_OF_LIST) {
                if (currentPos == NOT_FOUND && ptr == target) {
                    currentPos = prev;
                }
                if (nextPos == NOT_FOUND && _list[ptr].value < newValue) {
                    nextPos = prev;
                }
                if (currentPos != NOT_FOUND && nextPos != NOT_FOUND) {
                    break;
                }
                prev = ptr;
                ptr = _list[ptr].next;
            }

            require(currentPos != NOT_FOUND, "current position not found");
            prevValue = _list[target].value;

            if (nextPos == NOT_FOUND) {
                nextPos = prev;
            }

            if (nextPos == DUMMY || currentPos == DUMMY) {
                if (nextPos == DUMMY && currentPos == DUMMY) { // not change
                } else if (currentPos == DUMMY) {
                    _head = _list[target].next;
                    _list[target].next = _list[nextPos].next;
                    _list[nextPos].next = target;
                } else {
                    // nextPos == DUMMY
                    _list[currentPos].next = _list[target].next;
                    _list[target].next = _head;
                    _head = target;
                }
            } else {
                // 1. not moved
                if (currentPos == nextPos || _list[currentPos].next == nextPos) {} else {
                    _list[currentPos].next = _list[target].next;
                    _list[target].next = _list[nextPos].next;
                    _list[nextPos].next = target;
                }
            }
            _list[target].value = newValue;
            // check();
        } else {
            _addElement(target, newValue);
        }
        emit UpdateElement(target, prevValue, newValue);
    }

    function _removeElement(
        address target
    ) internal {
        require(_participated[target] != false, "not found in the list");
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
        require(ptr != END_OF_LIST, "not found");

        if (prev == DUMMY) {
            _head = _list[ptr].next;
        } else {
            _list[prev].next = _list[ptr].next;
        }
        delete _list[ptr];
        _participated[ptr] = false;
        --_listLength;

        emit RemoveElement(target);
    }
}
