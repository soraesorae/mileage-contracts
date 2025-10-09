// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {AdminHarness} from "./AdminHarness.sol";

contract AdminTest is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    AdminHarness adminContract;

    function setUp() public {
        vm.prank(alice);
        adminContract = new AdminHarness();
    }

    function test_addAdmin_Admin() public {
        vm.prank(alice);
        adminContract.addAdmin(bob);
        assertEq(adminContract.isAdmin(bob), true);
        assertEq(adminContract.isAdmin(alice), true);
    }

    function test_addAdmin_NotAdmin() public {
        assertEq(adminContract.isAdmin(bob), false);
        vm.expectRevert("caller is not the admin");
        vm.prank(bob);
        adminContract.addAdmin(bob);
    }

    function test_removeAdmin_Admin() public {
        vm.prank(alice);
        adminContract.addAdmin(bob);
        assertEq(adminContract.isAdmin(bob), true);
        vm.prank(alice);
        adminContract.removeAdmin(bob);
        assertEq(adminContract.isAdmin(bob), false);
    }

    function test_removeAdmin_NotAdmin() public {
        assertEq(adminContract.isAdmin(bob), false);
        vm.expectRevert("caller is not the admin");
        vm.prank(bob);
        adminContract.removeAdmin(bob);
    }

    function test_removeAdmin_self() public {
        vm.prank(alice);
        adminContract.addAdmin(bob);
        assertEq(adminContract.isAdmin(bob), true);
        vm.prank(bob);
        adminContract.removeAdmin(bob);
        assertEq(adminContract.isAdmin(bob), false);
    }

    function test_isAdmin() public view {
        assertEq(adminContract.isAdmin(alice), true);
    }

    function test_onlyAdmin_Admin() public {
        vm.prank(alice);
        adminContract.checkAdmin();
    }

    function test_onlyAdmin_NotAdmin() public {
        assertEq(adminContract.isAdmin(bob), false);
        vm.expectRevert("caller is not the admin");
        vm.prank(bob);
        adminContract.checkAdmin();
    }
}
