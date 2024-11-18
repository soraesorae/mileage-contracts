// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IKIP7} from "kaia-contracts/contracts/KIP/token/KIP7/IKIP7.sol";
import {SwMileageToken} from "../src/SwMileageToken.sol";
import {SortedList} from "../src/SortedList.sol";

contract SwMileageTokenTest is Test {
    SwMileageToken public mileageToken;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");

    function setUp() public {
        vm.prank(alice);
        mileageToken = new SwMileageToken("SwMileageToken", "SMT");
        vm.label(address(mileageToken), "mileageToken");
    }

    function test_token() public view {
        assertEq("SwMileageToken", mileageToken.name());
        assertEq("SMT", mileageToken.symbol());
    }

    function test_isAdmin() public view {
        assertEq(mileageToken.isAdmin(alice), true);
    }

    function test_mint_Admin() public {
        vm.expectEmit(address(mileageToken));
        emit IKIP7.Transfer(address(0), bob, 10);

        vm.expectEmit(address(mileageToken));
        emit SortedList.UpdateElement(bob, 0, 10);

        vm.prank(alice);
        mileageToken.mint(bob, 10);

        assertEq(mileageToken.balanceOf(bob), 10);
    }

    function test_mint_NoAdmin() public {
        vm.prank(alice);
        mileageToken.mint(bob, 10);

        vm.expectRevert(bytes("caller is not the admin"));
        vm.prank(charlie);
        mileageToken.burnFrom(bob, 1);
    }

    function test_mint_Twice() public {
        vm.startPrank(alice);

        vm.expectEmit(address(mileageToken));
        emit IKIP7.Transfer(address(0), bob, 10);

        vm.expectEmit(address(mileageToken));
        emit SortedList.UpdateElement(bob, 0, 10);

        mileageToken.mint(bob, 10);

        assertEq(mileageToken.balanceOf(bob), 10);

        vm.expectEmit(address(mileageToken));
        emit IKIP7.Transfer(address(0), charlie, 20);

        mileageToken.mint(charlie, 20);

        assertEq(mileageToken.balanceOf(charlie), 20);
        // SwMileageToken.Student[] memory students = mileageToken.getRankingRange(1, 1024);
        // assertEq(students.length, 1);
        // assertEq(students[0].addr, bob);
        // assertEq(students[0].balance, 10);
    }

    function test_burn_Admin() public {
        vm.startPrank(alice);
        mileageToken.mint(alice, 10);
        mileageToken.burn(5);

        assertEq(mileageToken.balanceOf(alice), 10);
    }

    function test_burn_NotAdmin() public {
        vm.prank(alice);
        mileageToken.mint(bob, 10);

        vm.prank(bob);
        mileageToken.burn(5);

        assertEq(mileageToken.balanceOf(bob), 10);
    }

    function test_burnFrom_Admin() public {
        vm.startPrank(alice);

        vm.expectEmit(address(mileageToken));
        emit IKIP7.Transfer(address(0), bob, 10);

        mileageToken.mint(bob, 10);
        assertEq(mileageToken.allowance(bob, alice), 0);

        vm.expectEmit(address(mileageToken));
        emit IKIP7.Transfer(bob, address(0), 5);

        mileageToken.burnFrom(bob, 5);
        assertEq(mileageToken.balanceOf(bob), 5);
    }

    function test_burnFrom_NotAdmin() public {
        vm.prank(alice);
        mileageToken.mint(bob, 10);

        vm.expectRevert(bytes("caller is not the admin"));
        vm.prank(charlie);
        mileageToken.burnFrom(charlie, 1);
    }

    function test_getRankingRange() public {
        vm.startPrank(alice);
        mileageToken.mint(alice, 0x1);
        mileageToken.mint(bob, 0x10);
        mileageToken.mint(charlie, 0x1000);

        SwMileageToken.Student[] memory students1 = mileageToken.getRankingRange(1, 2);

        assertEq(students1[0].account, charlie);
        assertEq(students1[1].account, bob);

        mileageToken.mint(alice, 0x10);

        SwMileageToken.Student[] memory students2 = mileageToken.getRankingRange(1, 10);

        assertEq(students2[0].account, charlie);
        assertEq(students2[1].account, alice);
        assertEq(students2[2].account, bob);

        mileageToken.burnFrom(charlie, 0x1000);

        SwMileageToken.Student[] memory students3 = mileageToken.getRankingRange(1, 10);

        assertEq(students3[0].account, alice);
        assertEq(students3[1].account, bob);
    }

    function test_addAdmin() public {
        vm.expectRevert("caller is not the admin");
        vm.prank(bob);
        mileageToken.mint(bob, 0x10);

        vm.prank(alice);
        mileageToken.addAdmin(bob);

        vm.prank(bob);
        mileageToken.mint(bob, 0x10);

        assertEq(mileageToken.balanceOf(bob), 0x10);
    }

    function test_removeAdmin() public {
        vm.expectRevert("caller is not the admin");
        vm.prank(bob);
        mileageToken.mint(bob, 0x10);

        vm.prank(alice);
        mileageToken.addAdmin(bob);

        vm.startPrank(bob);
        mileageToken.mint(bob, 0x10);

        assertEq(mileageToken.balanceOf(bob), 0x10);
        vm.stopPrank();

        vm.prank(alice);
        mileageToken.removeAdmin(bob);

        vm.expectRevert("caller is not the admin");
        vm.prank(bob);
        mileageToken.mint(bob, 0x10);
    }

    function test_transfer_NotPermitted() public {}
}
