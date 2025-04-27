// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract SwMileageTokenScript is Script {
    address alice = address(0x1234);

    function setUp() public {}

    function run() public {
        vm.startBroadcast(alice);

        vm.stopBroadcast();
    }
}
