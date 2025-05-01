// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SwMileageTokenImpl} from "../src/SwMileageTokenImpl.sol";
import {SwMileageTokenFactory} from "../src/SwMileageFactory.sol";

interface Ownable {
    function owner() external view returns (address);
}

contract SwMileageFactoryTest is Test {
    // SwMileageToken public mileageToken;
    SwMileageTokenImpl public impl;
    SwMileageTokenFactory public factory;
    address alice = makeAddr("alice");

    function setUp() public {
        vm.startPrank(alice);
        impl = new SwMileageTokenImpl();
        factory = new SwMileageTokenFactory(address(impl));
        console.log(address(this));
        console.log(address(factory));
        vm.stopPrank();
    }

    function test_deploy() public {
        vm.prank(alice);
        SwMileageTokenImpl deployed = SwMileageTokenImpl(factory.deploy("SwMileageToken2025", "SMT2025"));
        assertEq(deployed.name(), "SwMileageToken2025");
        assertEq(deployed.symbol(), "SMT2025");
        assertEq(deployed.isAdmin(alice), true);
    }
}
