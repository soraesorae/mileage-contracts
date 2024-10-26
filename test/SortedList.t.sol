// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SortedList} from "../src/SortedList.sol";

contract BubbleSort {
    address[] private _addr;
    mapping(address => uint256) private _value;

    constructor(address[] memory addr_, uint256[] memory value_) {
        for (uint256 i = 0; i < addr_.length; i++) {
            _addr.push(addr_[i]);
            _value[addr_[i]] = value_[i];
        }
    }

    /// @dev bubble sort desc
    /// reference: https://en.wikipedia.org/wiki/Bubble_sort
    ///
    function sort() public view returns (address[] memory) {
        uint256 n = _addr.length;
        address[] memory sorted = new address[](n);
        for (uint256 i = 0; i < n; i++) {
            sorted[i] = _addr[i];
        }
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (_value[sorted[j]] < _value[sorted[j + 1]]) {
                    (sorted[j], sorted[j + 1]) = (sorted[j + 1], sorted[j]);
                }
            }
        }
        return sorted;
    }
}

contract BubbleSortTest is Test {
    BubbleSort bubble_sort;

    function setUp() public {
        address[] memory addr = new address[](7);
        uint256[] memory value = new uint256[](7);
        addr[0] = address(0x1);
        value[0] = 10;
        addr[1] = address(0x2);
        value[1] = 5;
        addr[2] = address(0x3);
        value[2] = 10;
        addr[3] = address(0x4);
        value[3] = 1;
        addr[4] = address(0x5);
        value[4] = 7;
        addr[5] = address(0x6);
        value[5] = 7;
        addr[6] = address(0x7);
        value[6] = 11;

        bubble_sort = new BubbleSort(addr, value);
    }

    function test_BubbleSort() public view {
        address[] memory sorted = bubble_sort.sort();

        assertEq(sorted[0], address(0x7));
        assertEq(sorted[1], address(0x1));
        assertEq(sorted[2], address(0x3));
        assertEq(sorted[3], address(0x5));
        assertEq(sorted[4], address(0x6));
        assertEq(sorted[5], address(0x2));
        assertEq(sorted[6], address(0x4));
    }
}

contract SortedListTest is SortedList, Test {
    address alice = address(0x1234);
    address bob = address(0x4321);

    function setUp() public {}

    function test_AddElement() public {
        _addElement(address(0x1234), 0x1000);
    }

    function testFail_DuplicateNode() public {
        _addElement(address(0xAAAA), 0x1);
        _addElement(address(0xAAAA), 0x1);
    }

    function test_GetAllElement() public {
        for (uint256 i = 0; i < 128; i++) {
            _addElement(address(uint160(127 - i)), i);
        }
        DataPair[] memory result = abi.decode(_getAllElement(), (DataPair[]));
        for (uint256 i = 0; i < 128; i++) {
            assertEq(result[i].addr, address(uint160(i)));
            assertEq(result[i].value, 127 - i);
        }
    }

    function test_GetAllElementStablity() public {
        address[] memory addr = new address[](7);
        uint256[] memory value = new uint256[](7);
        addr[0] = address(0x1);
        value[0] = 10;
        addr[1] = address(0x2);
        value[1] = 5;
        addr[2] = address(0x3);
        value[2] = 10;
        addr[3] = address(0x4);
        value[3] = 1;
        addr[4] = address(0x5);
        value[4] = 7;
        addr[5] = address(0x6);
        value[5] = 7;
        addr[6] = address(0x7);
        value[6] = 11;

        // addr = [1, 2, 3, 4, 5, 6, 7]
        // value = [10, 5, 10, 1, 7, 7, 11]

        _addElement(addr[0], value[0]);
        _addElement(addr[1], value[1]);
        _addElement(addr[2], value[2]);
        _addElement(addr[3], value[3]);
        _addElement(addr[4], value[4]);
        _addElement(addr[5], value[5]);
        _addElement(addr[6], value[6]);

        DataPair[] memory result = abi.decode(_getAllElement(), (DataPair[]));

        // expected address list = [7, 1, 3, 5, 6, 2, 4]

        assertEq(result[0].addr, address(0x7));
        assertEq(result[1].addr, address(0x1));
        assertEq(result[2].addr, address(0x3));
        assertEq(result[3].addr, address(0x5));
        assertEq(result[4].addr, address(0x6));
        assertEq(result[5].addr, address(0x2));
        assertEq(result[6].addr, address(0x4));
    }

    function test_UpdateElement() public {
        address[] memory addr = new address[](7);
        uint256[] memory value = new uint256[](7);

        addr[0] = address(0x1);
        value[0] = 10;
        addr[1] = address(0x2);
        value[1] = 5;
        addr[2] = address(0x3);
        value[2] = 10;
        addr[3] = address(0x4);
        value[3] = 1;
        addr[4] = address(0x5);
        value[4] = 7;
        addr[5] = address(0x6);
        value[5] = 7;
        addr[6] = address(0x7);
        value[6] = 11;

        // addr = [1, 2, 3, 4, 5, 6, 7]
        // value = [10, 5, 10, 1, 7, 7, 11]
        // expected address list = [7, 1, 3, 5, 6, 2, 4]

        _addElement(addr[0], value[0]);
        _addElement(addr[1], value[1]);
        _addElement(addr[2], value[2]);
        _addElement(addr[3], value[3]);
        _addElement(addr[4], value[4]);
        _addElement(addr[5], value[5]);
        _addElement(addr[6], value[6]);

        _updateElement(addr[6], 0);
        DataPair[] memory result = abi.decode(_getAllElement(), (DataPair[]));

        assertEq(result[0].addr, address(0x1));
    }

    function testFuzz_GetAllElemnt(DataPair[] memory pair) public {
        vm.assume(0 < pair.length && pair.length <= 1000);
        for (uint256 i = 0; i < pair.length; i++) {
            vm.assume(pair[i].addr > address(0xffffffff));
            _addElement(pair[i].addr, pair[i].value);
        }

        address[] memory addr = new address[](pair.length);
        uint256[] memory value = new uint256[](pair.length);

        for (uint256 i = 0; i < pair.length; i++) {
            addr[i] = pair[i].addr;
            value[i] = pair[i].value;
        }

        BubbleSort bs = new BubbleSort(addr, value);

        address[] memory sorted = bs.sort();

        DataPair[] memory result = abi.decode(_getAllElement(), (DataPair[]));

        for (uint256 i = 0; i < addr.length; i++) {
            assertEq(result[i].addr, sorted[i]);
        }
    }
    // event test
    // failure test
}
