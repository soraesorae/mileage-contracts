// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SortedList} from "../src/SortedList.sol";
import {ISortedList} from "../src/ISortedList.sol";
import {MockSortedList} from "./MockSortedList.sol";

contract SortedListTest is Test {
    MockSortedList list;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");
    address dave = makeAddr("dave");
    address eve = makeAddr("eve");

    function setUp() public {
        list = new MockSortedList();
    }

    function test_getListLength_empty() public view {
        assertEq(list.getListLength(), 0);
        assertEq(list.getAll().length, 0);
    }

    function test_updateElement_firstElement() public {
        list.update(alice, 100);

        assertEq(list.getListLength(), 1);
        ISortedList.DataPair[] memory elements = list.getAll();
        assertEq(elements[0].addr, alice);
        assertEq(elements[0].value, 100);
    }

    function test_updateElement_multipleElements() public {
        list.update(alice, 100);
        list.update(bob, 200);
        list.update(charlie, 50);

        ISortedList.DataPair[] memory elements = list.getAll();

        assertEq(elements[0].addr, bob);
        assertEq(elements[0].value, 200);
        assertEq(elements[1].addr, alice);
        assertEq(elements[1].value, 100);
        assertEq(elements[2].addr, charlie);
        assertEq(elements[2].value, 50);
    }

    function test_updateElement_valueUpdate() public {
        list.update(alice, 100);
        list.update(alice, 200);

        assertEq(list.getListLength(), 1);
        assertEq(list.getAll()[0].addr, alice);
        assertEq(list.getAll()[0].value, 200);
    }

    function test_updateElement_sameValue() public {
        list.update(alice, 100);
        list.update(alice, 100);

        assertEq(list.getListLength(), 1);
        assertEq(list.getAll()[0].addr, alice);
        assertEq(list.getAll()[0].value, 100);
    }

    function test_updateElement_changesOrder() public {
        list.update(alice, 300);
        list.update(bob, 200);
        list.update(charlie, 100);

        list.update(bob, 400);

        ISortedList.DataPair[] memory elements = list.getAll();
        assertEq(elements[0].addr, bob);
        assertEq(elements[0].value, 400);
        assertEq(elements[1].addr, alice);
        assertEq(elements[1].value, 300);
        assertEq(elements[2].addr, charlie);
        assertEq(elements[2].value, 100);
    }

    function test_updateElement_toZero() public {
        list.update(alice, 300);
        list.update(bob, 200);

        list.update(alice, 0);

        ISortedList.DataPair[] memory elements = list.getAll();
        assertEq(elements[0].addr, bob);
        assertEq(elements[0].value, 200);
        assertEq(elements[1].addr, alice);
        assertEq(elements[1].value, 0);
    }

    function test_updateElement_sameValueMultiple() public {
        list.update(alice, 100);
        list.update(bob, 100);
        list.update(charlie, 100);

        ISortedList.DataPair[] memory elements = list.getAll();
        assertEq(elements.length, 3);

        for (uint256 i = 0; i < 3; i++) {
            assertEq(elements[i].value, 100);
        }

        assertEq(elements[0].addr, alice);
        assertEq(elements[1].addr, bob);
        assertEq(elements[2].addr, charlie);
    }

    function test_updateElement_sortingWithEqualValues() public {
        address[] memory addresses = new address[](5);
        for (uint256 i = 0; i < addresses.length; i++) {
            addresses[i] = address(uint160(0x1000 + i));
        }

        uint256 sameValue = 100;

        for (uint256 i = 0; i < addresses.length; i++) {
            list.update(addresses[i], sameValue);
        }

        ISortedList.DataPair[] memory elements = list.getAll();

        assertEq(elements.length, addresses.length);

        for (uint256 i = 0; i < elements.length; i++) {
            assertEq(elements[i].value, sameValue);
        }

        bool[] memory found = new bool[](addresses.length);
        for (uint256 i = 0; i < elements.length; i++) {
            for (uint256 j = 0; j < addresses.length; j++) {
                if (elements[i].addr == addresses[j]) {
                    found[j] = true;
                }
            }
        }

        bool flag = true;

        for (uint256 i = 0; i < addresses.length; i++) {
            if (found[i] == false) {
                flag = false;
            }
        }

        assertTrue(flag);

        address newAddr = address(0x2000);
        uint256 higherValue = sameValue + 50;
        list.update(newAddr, higherValue);

        elements = list.getAll();

        assertEq(elements[0].addr, newAddr);
        assertEq(elements[0].value, higherValue);

        assertEq(elements.length, addresses.length + 1);
    }

    function test_removeElement_middle() public {
        list.update(alice, 300);
        list.update(bob, 200);
        list.update(charlie, 100);

        list.remove(bob);

        ISortedList.DataPair[] memory elements = list.getAll();
        assertEq(elements.length, 2);
        assertEq(elements[0].addr, alice);
        assertEq(elements[1].addr, charlie);
    }

    function test_removeElement_head() public {
        list.update(alice, 300);
        list.update(bob, 200);

        list.remove(alice);

        ISortedList.DataPair[] memory elements = list.getAll();
        assertEq(elements.length, 1);
        assertEq(elements[0].addr, bob);
    }

    function test_removeElement_tail() public {
        list.update(alice, 300);
        list.update(bob, 200);

        list.remove(bob);

        ISortedList.DataPair[] memory elements = list.getAll();
        assertEq(elements.length, 1);
        assertEq(elements[0].addr, alice);
    }

    function test_removeElement_onlyElement() public {
        list.update(alice, 100);
        list.remove(alice);

        assertEq(list.getListLength(), 0);
    }

    function test_removeElement_addressNotFound() public {
        vm.expectRevert("not found in the list");
        list.remove(alice);

        list.update(bob, 100);
        vm.expectRevert("not found in the list");
        list.remove(alice);
    }

    function test_getElementRange_multiple() public {
        list.update(alice, 300);
        list.update(bob, 200);
        list.update(charlie, 100);
        list.update(dave, 50);
        list.update(eve, 25);

        ISortedList.DataPair[] memory elements = list.getRange(2, 4);

        assertEq(elements.length, 3);

        assertEq(elements[0].value, 200);
        assertEq(elements[1].value, 100);
        assertEq(elements[2].value, 50);

        assertEq(elements[0].addr, bob);
        assertEq(elements[1].addr, charlie);
        assertEq(elements[2].addr, dave);
    }

    function test_getElementRange_single() public {
        list.update(alice, 300);
        list.update(bob, 200);
        list.update(charlie, 100);

        ISortedList.DataPair[] memory elements = list.getRange(2, 2);

        assertEq(elements.length, 1);
        assertEq(elements[0].addr, bob);
    }

    function test_getElementRange_emptyResults() public {
        ISortedList.DataPair[] memory elements = list.getRange(1, 5);
        assertEq(elements.length, 0);

        list.update(alice, 300);
        list.update(bob, 200);
        elements = list.getRange(3, 5);
        assertEq(elements.length, 0);
    }

    function test_getElementIndex_tracking() public {
        list.update(alice, 300);
        list.update(bob, 200);
        list.update(charlie, 100);

        assertEq(list.indexOf(alice), 1);
        assertEq(list.indexOf(bob), 2);
        assertEq(list.indexOf(charlie), 3);

        list.update(charlie, 400);

        assertEq(list.indexOf(charlie), 1);
        assertEq(list.indexOf(alice), 2);
        assertEq(list.indexOf(bob), 3);

        list.remove(alice);

        assertEq(list.indexOf(charlie), 1);
        assertEq(list.indexOf(bob), 2);
        assertEq(list.indexOf(alice), -1);
    }

    function test_getElementIndex_invalidAccess() public {
        address nope = makeAddr("nope");
        list.update(alice, 100);
        list.update(bob, 200);

        assertEq(list.indexOf(alice), 2);
        assertEq(list.indexOf(bob), 1);

        assertEq(list.indexOf(nope), -1);

        vm.expectRevert("Element not found");
        list.valueOf(nope);
    }

    function test_updateElement_extremeValue() public {
        list.update(alice, 100);

        uint256 maxValue = type(uint256).max;
        list.update(alice, maxValue);

        assertEq(list.valueOf(alice), maxValue);

        list.update(alice, 50);
        assertEq(list.valueOf(alice), 50);
    }

    function test_updateElement_largeNumberOfElements() public {
        uint256 elementCount = 50;

        for (uint256 i = 0; i < elementCount; i++) {
            address addr = address(uint160(0x1000 + i));
            list.update(addr, elementCount - i);
        }

        assertEq(list.getListLength(), elementCount);

        ISortedList.DataPair[] memory elements = list.getAll();
        for (uint256 i = 0; i < elementCount - 1; i++) {
            assertTrue(elements[i].value >= elements[i + 1].value);
        }
    }

    function test_pattern1() public {
        list.update(alice, 100);
        list.update(bob, 200);
        list.update(charlie, 300);
        list.update(dave, 400);

        list.update(alice, 500);
        list.update(dave, 50);
        list.update(bob, 600);
        list.update(charlie, 550);

        {
            ISortedList.DataPair[] memory elements = list.getAll();
            assertEq(elements[0].addr, bob);
            assertEq(elements[1].addr, charlie);
            assertEq(elements[2].addr, alice);
            assertEq(elements[3].addr, dave);
        }

        list.remove(bob);
        list.remove(charlie);
        list.remove(alice);
        list.remove(dave);

        list.update(alice, 100);
        list.update(bob, 200);
        list.update(charlie, 300);
        list.update(dave, 400);
        list.update(eve, 500);

        list.remove(charlie);
        list.remove(eve);
        list.remove(alice);

        {
            ISortedList.DataPair[] memory elements = list.getAll();
            assertEq(elements.length, 2);
            assertEq(elements[0].addr, dave);
            assertEq(elements[1].addr, bob);
        }

        list.remove(dave);
        list.remove(bob);

        assertEq(list.getListLength(), 0);
    }

    function test_updateElement_repeatedSameValue() public {
        list.update(alice, 100);
        list.update(bob, 200);

        for (uint256 i = 0; i < 5; i++) {
            list.update(alice, 100);
        }

        ISortedList.DataPair[] memory elements = list.getAll();
        assertEq(elements.length, 2);
        assertEq(elements[0].addr, bob);
        assertEq(elements[1].addr, alice);
    }

    function test_reverts() public {
        vm.expectRevert("not found in the list");
        list.remove(alice);

        list.update(alice, 100);
        vm.expectRevert("address already exists");
        list.push(alice, 200);

        list.remove(alice);
        vm.expectRevert("empty list");
        list.pop();

        vm.expectRevert("from == 0");
        list.getRange(0, 5);

        vm.expectRevert("to < from");
        list.getRange(5, 3);
    }

    function test_updateElement_zeroValueTransitions() public {
        list.update(alice, 100);
        list.update(bob, 200);
        list.update(charlie, 300);

        list.update(alice, 0);
        list.update(bob, 0);

        {
            ISortedList.DataPair[] memory elements = list.getAll();
            assertEq(elements[0].addr, charlie);
            assertEq(elements[0].value, 300);

            bool foundAlice = false;
            bool foundBob = false;

            for (uint256 i = 1; i < 3; i++) {
                if (elements[i].addr == alice) {
                    foundAlice = true;
                    assertEq(elements[i].value, 0);
                }
                if (elements[i].addr == bob) {
                    foundBob = true;
                    assertEq(elements[i].value, 0);
                }
            }

            assertTrue(foundAlice && foundBob);
        }

        list.update(alice, 400);
        list.update(bob, 350);

        {
            ISortedList.DataPair[] memory elements = list.getAll();
            assertEq(elements[0].addr, alice);
            assertEq(elements[0].value, 400);
            assertEq(elements[1].addr, bob);
            assertEq(elements[1].value, 350);
            assertEq(elements[2].addr, charlie);
            assertEq(elements[2].value, 300);
        }
    }

    function test_pattern2() public {
        list.update(alice, 100);
        list.update(bob, 200);
        list.update(charlie, 300);

        list.update(alice, 250);
        list.remove(bob);
        list.update(dave, 150);

        {
            ISortedList.DataPair[] memory elements = list.getAll();
            assertEq(elements.length, 3);
            assertEq(elements[0].addr, charlie);
            assertEq(elements[0].value, 300);
            assertEq(elements[1].addr, alice);
            assertEq(elements[1].value, 250);
            assertEq(elements[2].addr, dave);
            assertEq(elements[2].value, 150);
        }

        list.remove(charlie);
        list.remove(alice);
        list.remove(dave);

        list.update(alice, 100);
        list.update(bob, 200);
        list.remove(bob);
        list.update(charlie, 300);
        list.update(dave, 150);
        list.remove(alice);
        list.update(eve, 250);

        {
            ISortedList.DataPair[] memory elements = list.getAll();
            assertEq(elements.length, 3);
            assertEq(elements[0].addr, charlie);
            assertEq(elements[1].addr, eve);
            assertEq(elements[2].addr, dave);
        }

        list.update(dave, 400);

        {
            ISortedList.DataPair[] memory elements = list.getAll();
            assertEq(elements[0].addr, dave);
            assertEq(elements[1].addr, charlie);
            assertEq(elements[2].addr, eve);
        }
    }

    function test_removeElement_listLengthDecrement() public {
        address testAddr = address(0x1234);
        list.update(testAddr, 100);

        assertEq(list.getListLength(), 1);

        ISortedList.DataPair[] memory elements = list.getAll();
        assertEq(elements.length, 1);
        assertEq(elements[0].addr, testAddr);

        list.remove(testAddr);

        assertEq(list.getListLength(), 0);
        elements = list.getAll();
        assertEq(elements.length, 0);
    }

    function test_removeAndReadd() public {
        list.update(alice, 100);

        list.remove(alice);

        assertEq(list.getListLength(), 0);
        assertEq(list.indexOf(alice), -1);

        list.update(alice, 200);

        assertEq(list.getListLength(), 1);
        assertEq(list.indexOf(alice), 1);
        assertEq(list.valueOf(alice), 200);
    }

    function test_getElementRange_invalidParameters() public {
        vm.expectRevert("from == 0");
        list.getRange(0, 5);

        vm.expectRevert("to < from");
        list.getRange(5, 3);
    }
}
