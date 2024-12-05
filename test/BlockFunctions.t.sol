// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IKIP7} from "kaia-contracts/contracts/KIP/token/KIP7/IKIP7.sol";
import {SwMileageToken} from "../src/SwMileageToken.sol";

contract SwMileageTokenBlockFunctionsTest is Test {
    SwMileageToken public mileageToken;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");

    function setUp() public {
        vm.prank(alice);
        mileageToken = new SwMileageToken("SwMileageToken", "SMT");
        vm.label(address(mileageToken), "mileageToken");
    }

    function testBlockKIP7Transfer() public {
        vm.prank(alice);
        mileageToken.mint(bob, 10);
        vm.expectRevert("Blocked");
        vm.prank(bob);
        mileageToken.transfer(alice, 10);
    }

    function testBlockKIP7TransferFrom() public {
        vm.prank(alice);
        mileageToken.mint(bob, 10);
        vm.expectRevert("Blocked");
        vm.prank(bob);
        mileageToken.approve(charlie, 10);
    }
}
