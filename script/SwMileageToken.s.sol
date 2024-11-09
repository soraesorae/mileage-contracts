// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SwMileageToken} from "../src/SwMileageToken.sol";

contract SwMileageTokenScript is Script {
    SwMileageToken public token;

    address alice = address(0x1234);

    function setUp() public {}

    function run() public {
        vm.startBroadcast(alice);

        token = new SwMileageToken("SwMileageToken", "SMT");

        vm.stopBroadcast();
    }
}
