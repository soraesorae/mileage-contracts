// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MockSortedList} from "./MockSortedList.sol";
import {BubbleSort} from "./utils/BubbleSort.sol";

contract SortedListTest is BubbleSort, Test {
    struct DataPair {
        address addr;
        uint256 value;
    }

    address alice = address(0x1234);
    address bob = address(0x4321);
    MockSortedList mockSortedList;

    function setUp() public {
        mockSortedList = new MockSortedList();
    }

    function test_AddElement() public {
        mockSortedList.addElement(address(0x1234), 0x1000);
    }

    function testFail_DuplicateNode() public {
        mockSortedList.addElement(address(0xAAAA), 0x1);
        mockSortedList.addElement(address(0xAAAA), 0x1);
    }

    function test_GetAllElement() public {
        for (uint256 i = 0; i < 128; i++) {
            mockSortedList.addElement(address(uint160(127 - i)), i);
        }
        DataPair[] memory result = abi.decode(mockSortedList.getAllElement(), (DataPair[]));
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

        mockSortedList.addElement(addr[0], value[0]);
        mockSortedList.addElement(addr[1], value[1]);
        mockSortedList.addElement(addr[2], value[2]);
        mockSortedList.addElement(addr[3], value[3]);
        mockSortedList.addElement(addr[4], value[4]);
        mockSortedList.addElement(addr[5], value[5]);
        mockSortedList.addElement(addr[6], value[6]);

        DataPair[] memory result = abi.decode(mockSortedList.getAllElement(), (DataPair[]));

        // expected address list = [7, 1, 3, 5, 6, 2, 4]

        assertEq(result[0].addr, address(0x7));
        assertEq(result[1].addr, address(0x1));
        assertEq(result[2].addr, address(0x3));
        assertEq(result[3].addr, address(0x5));
        assertEq(result[4].addr, address(0x6));
        assertEq(result[5].addr, address(0x2));
        assertEq(result[6].addr, address(0x4));
    }

    function test_GetElementRange() public {
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

        mockSortedList.addElement(addr[0], value[0]);
        mockSortedList.addElement(addr[1], value[1]);
        mockSortedList.addElement(addr[2], value[2]);
        mockSortedList.addElement(addr[3], value[3]);
        mockSortedList.addElement(addr[4], value[4]);
        mockSortedList.addElement(addr[5], value[5]);
        mockSortedList.addElement(addr[6], value[6]);

        DataPair[] memory result;

        result = abi.decode(mockSortedList.getElementRange(1, 1), (DataPair[]));
        assertEq(result.length, 1);
        assertEq(result[0].addr, addr[6]);

        result = abi.decode(mockSortedList.getElementRange(7, 7), (DataPair[]));
        assertEq(result.length, 1);
        assertEq(result[0].addr, addr[3]);

        result = abi.decode(mockSortedList.getElementRange(3, 100), (DataPair[]));
        assertEq(result.length, 5);
        assertEq(result[0].addr, addr[2]);

        result = abi.decode(mockSortedList.getElementRange(3, 6), (DataPair[]));
        assertEq(result.length, 4);
        assertEq(result[0].addr, addr[2]);

        vm.expectRevert();
        mockSortedList.getElementRange(0, 100);

        vm.expectRevert();
        mockSortedList.getElementRange(3, 2);
    }

    function compare(address[7] memory expected) private view {
        DataPair[] memory result = abi.decode(mockSortedList.getAllElement(), (DataPair[]));
        for (uint256 i = 0; i < 7; i++) {
            assertEq(result[i].addr, expected[i]);
        }
    }

    function test_UpdateElement() public {
        uint256 n = 7;
        address[] memory addr = new address[](n);
        uint256[] memory value = new uint256[](n);

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

        mockSortedList.addElement(addr[0], value[0]);
        mockSortedList.addElement(addr[1], value[1]);
        mockSortedList.addElement(addr[2], value[2]);
        mockSortedList.addElement(addr[3], value[3]);
        mockSortedList.addElement(addr[4], value[4]);
        mockSortedList.addElement(addr[5], value[5]);
        mockSortedList.addElement(addr[6], value[6]);

        mockSortedList.updateElement(addr[6], 0); // 1 -> 7
        compare([addr[0], addr[2], addr[4], addr[5], addr[1], addr[3], addr[6]]);

        mockSortedList.updateElement(addr[5], 6); // not move
        compare([addr[0], addr[2], addr[4], addr[5], addr[1], addr[3], addr[6]]);

        mockSortedList.updateElement(addr[5], 5); // 4 -> 5
        compare([addr[0], addr[2], addr[4], addr[1], addr[5], addr[3], addr[6]]);

        mockSortedList.updateElement(addr[2], 11); // 2 -> 1
        compare([addr[2], addr[0], addr[4], addr[1], addr[5], addr[3], addr[6]]);
        // compare(expected);
    }

    function testFuzz_GetAllElemnt(uint256[] memory values) public {
        vm.assume(0 < values.length && values.length <= 100);
        address[] memory addr = new address[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            addr[i] = address(uint160(i + 0x10000000));
            values[i] = bound(values[i], 0, 100);
            mockSortedList.addElement(addr[i], values[i]);
        }

        addDataArray(addr, values);

        address[] memory sorted = sort();

        DataPair[] memory result = abi.decode(mockSortedList.getAllElement(), (DataPair[]));

        for (uint256 i = 0; i < addr.length; i++) {
            assertEq(result[i].addr, sorted[i]);
        }
    }

    // not working
    //
    // function testFuzz_UpdateElement(uint256[10] calldata values, uint8[20] calldata moveIndex, uint8[20] calldata x) public {
    //     // vm.assume(moveIndex.length == x.length && 0 < moveIndex.length && moveIndex.length < 20);
    //     address[] memory addr = new address[](values.length);
    //     uint256[] memory updateValues = new uint256[](values.length);
    //     for (uint256 i = 0; i < values.length; i++) {
    //         addr[i] = address(uint160(i + 0x10000000));
    //         mockSortedList.addElement(addr[i], bound(values[i], 0, 10));
    //     }

    //     for (uint256 i = 0; i < moveIndex.length; i++) {
    //         uint8 index = uint8(bound(moveIndex[i], 0, 9));
    //         mockSortedList.updateElement(addr[index], uint256(x[i]));
    //         updateValues[index] = uint256(x[i]);
    //     }

    //     addDataArray(addr, updateValues);

    //     address[] memory sorted = sort();

    //     DataPair[] memory result = abi.decode(mockSortedList.getAllElement(), (DataPair[]));

    //     for (uint256 i = 0; i < addr.length; i++) {
    //         assertEq(result[i].addr, sorted[i], "Why!!");
    //     }
    // }

    // event test
    // failure test
}
