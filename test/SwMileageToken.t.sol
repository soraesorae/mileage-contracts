// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SwMaileageToken} from "../src/SwMileageToken.sol";

contract SwMaileageTokenTest is Test {
    SwMaileageToken public mileage_token;
    address alice = address(0x1234);

    function setUp() public {
        vm.prank(alice);
        mileage_token = new SwMaileageToken("SwMileageToken", "SMT");
    }

    function testToken() public view {
        assertEq("SwMileageToken", mileage_token.name());
        assertEq("SMT", mileage_token.symbol());
    }

    function testOwner() public view {
        assertEq(mileage_token.owner(), alice);
    }
}
