// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SortedList} from "../src/SortedList.sol";

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
            _addElement(address(uint160(i * 10)), 127 - i);
        }
        // 127 <- 126 <- 125 <- ... <- 0
        DataPair[] memory result = _getAllElement();
        for (uint256 i = 0; i < 128; i++) {
            assertEq(result[i].addr, address(uint160((127 - i) * 10)));
            assertEq(result[i].value, i);
        }
    }

    // event test
    // failure test
}
