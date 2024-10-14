// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SwMaileageToken} from "../src/SwMileageToken.sol";

contract SwMaileageTokenTest is Test {
    SwMaileageToken public mileage_token;

    function setUp() public {
        mileage_token = new SwMaileageToken();
    }

    function testToken() public view {
        assertEq("SwMileageToken", mileage_token.name());
        assertEq("SMT", mileage_token.symbol());
    }
}
