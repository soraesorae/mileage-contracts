// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SwMileageToken} from "../src/SwMileageToken.sol";

contract SwMileageTokenTest is Test {
    SwMileageToken public mileageToken;
    address alice = address(0x1234);
    address bob = address(0x4321);
    address charlie = address(0x1111);

    function setUp() public {
        vm.prank(alice);
        mileageToken = new SwMileageToken("SwMileageToken", "SMT");
    }

    function test_Token() public view {
        assertEq("SwMileageToken", mileageToken.name());
        assertEq("SMT", mileageToken.symbol());
    }

    function test_Owner() public view {
        assertEq(mileageToken.owner(alice), true);
    }

    function test_MintFirstTime() public {
        vm.prank(alice);
        mileageToken.mint(bob, 10);
        assertEq(mileageToken.balanceOf(bob), 10);
        SwMileageToken.Student[] memory students = mileageToken.getRankingRange(1, 1024);
        assertEq(students.length, 1);
        assertEq(students[0].wallet, bob);
        assertEq(students[0].balance, 10);
    }

    function test_BurnFromOwner() public {
        vm.startPrank(alice);
        mileageToken.mint(bob, 10);
        assertEq(mileageToken.allowance(bob, alice), 0);
        mileageToken.burnFrom(bob, 5);
        assertEq(mileageToken.balanceOf(bob), 5);
        vm.stopPrank();
    }

    function testFail_BurnFromRegular() public {
        vm.prank(alice);
        mileageToken.mint(bob, 10);

        vm.prank(charlie);
        mileageToken.burnFrom(charlie, 1);
    }

    function test_GetRankingRange() public {
        vm.startPrank(alice);
        mileageToken.mint(alice, 0x1);
        mileageToken.mint(bob, 0x10);
        mileageToken.mint(charlie, 0x1000);
        vm.stopPrank();

        SwMileageToken.Student[] memory students1 = mileageToken.getRankingRange(1, 2);

        assertEq(students1[0].wallet, charlie);
        assertEq(students1[1].wallet, bob);

        vm.prank(alice);
        mileageToken.mint(alice, 0x10);

        SwMileageToken.Student[] memory students2 = mileageToken.getRankingRange(1, 10);

        assertEq(students2[0].wallet, charlie);
        assertEq(students2[1].wallet, alice);
        assertEq(students2[2].wallet, bob);

        vm.prank(alice);
        mileageToken.burnFrom(charlie, 0x1000);

        SwMileageToken.Student[] memory students3 = mileageToken.getRankingRange(1, 10);

        assertEq(students3[0].wallet, alice);
        assertEq(students3[1].wallet, bob);
    }

    function test_AddOwnership() public {
        vm.expectRevert("caller is not the owner");
        vm.prank(bob);
        mileageToken.mint(bob, 0x10);

        vm.prank(alice);
        mileageToken.addOwnership(bob);

        vm.startPrank(bob);
        mileageToken.mint(bob, 0x10);

        assertEq(mileageToken.balanceOf(bob), 0x10);
        vm.stopPrank();
    }

    function test_RemoveOwnership() public {
        vm.expectRevert("caller is not the owner");
        vm.prank(bob);
        mileageToken.mint(bob, 0x10);

        vm.prank(alice);
        mileageToken.addOwnership(bob);

        vm.startPrank(bob);
        mileageToken.mint(bob, 0x10);

        assertEq(mileageToken.balanceOf(bob), 0x10);
        vm.stopPrank();

        vm.prank(alice);
        mileageToken.removeOwnership(bob);

        vm.expectRevert("caller is not the owner");
        vm.prank(bob);
        mileageToken.mint(bob, 0x10);
    }
}
