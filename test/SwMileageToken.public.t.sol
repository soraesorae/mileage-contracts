// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IKIP7} from "kaia-contracts/contracts/KIP/token/KIP7/IKIP7.sol";
import {SwMileageToken} from "../src/SwMileageToken.sol";
import {SortedList} from "../src/SortedList.sol";

contract SwMileageTokenBlockedTest is Test {
    SwMileageToken public mileageToken;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");

    function setUp() public {
        vm.startPrank(alice);
        mileageToken = new SwMileageToken("SwMileageToken", "SMT");
        vm.label(address(mileageToken), "mileageToken");
        mileageToken.mint(alice, 0x10);
        mileageToken.mint(bob, 0x11);
        mileageToken.mint(charlie, 0x12);
        vm.stopPrank();
    }
}
