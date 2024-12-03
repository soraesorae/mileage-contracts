// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Admin} from "../src/Admin.sol";
import {MockAdmin} from "./MockAdmin.sol";

contract AdminTest is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    MockAdmin mockAdmin;

    function setUp() public {
        vm.prank(alice);
        mockAdmin = new MockAdmin();
    }

    function test_addAdmin_Admin() public {
        vm.prank(alice);
        mockAdmin.addAdmin(bob);
        assertEq(mockAdmin.isAdmin(bob), true);
        assertEq(mockAdmin.isAdmin(alice), true);
    }

    function test_addAdmin_NotAdmin() public {
        assertEq(mockAdmin.isAdmin(bob), false);
        vm.expectRevert("caller is not the admin");
        vm.prank(bob);
        mockAdmin.addAdmin(bob);
    }

    function test_removeAdmin_Admin() public {
        vm.prank(alice);
        mockAdmin.addAdmin(bob);
        assertEq(mockAdmin.isAdmin(bob), true);
        vm.prank(alice);
        mockAdmin.removeAdmin(bob);
        assertEq(mockAdmin.isAdmin(bob), false);
    }

    function test_removeAdmin_NotAdmin() public {
        assertEq(mockAdmin.isAdmin(bob), false);
        vm.expectRevert("caller is not the admin");
        vm.prank(bob);
        mockAdmin.removeAdmin(bob);
    }

    function test_removeAdmin_self() public {
        vm.prank(alice);
        mockAdmin.addAdmin(bob);
        assertEq(mockAdmin.isAdmin(bob), true);
        vm.prank(bob);
        mockAdmin.removeAdmin(bob);
        assertEq(mockAdmin.isAdmin(bob), false);
    }

    function test_isAdmin() public view {
        assertEq(mockAdmin.isAdmin(alice), true);
    }

    function test_onlyAdmin_Admin() public {
        vm.prank(alice);
        mockAdmin.checkAdmin();
    }

    function test_onlyAdmin_NotAdmin() public {
        assertEq(mockAdmin.isAdmin(bob), false);
        vm.expectRevert("caller is not the admin");
        vm.prank(bob);
        mockAdmin.checkAdmin();
    }
}
