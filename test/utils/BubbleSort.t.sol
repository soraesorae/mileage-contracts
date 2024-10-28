// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BubbleSort} from "./BubbleSort.sol";

contract MockBubbleSort is BubbleSort {
    function addDataArray_(address[] memory addr_, uint256[] memory value_) public {
        addDataArray(addr_, value_);
    }

    function sort_() public view returns (address[] memory) {
        return sort();
    }
}

contract BubbleSortTest is Test {
    MockBubbleSort mockBubbleSort;

    function setUp() public {
        mockBubbleSort = new MockBubbleSort();

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

        mockBubbleSort.addDataArray_(addr, value);
    }

    function test_BubbleSort() public view {
        address[] memory sorted = mockBubbleSort.sort_();

        assertEq(sorted[0], address(0x7));
        assertEq(sorted[1], address(0x1));
        assertEq(sorted[2], address(0x3));
        assertEq(sorted[3], address(0x5));
        assertEq(sorted[4], address(0x6));
        assertEq(sorted[5], address(0x2));
        assertEq(sorted[6], address(0x4));
    }
}
