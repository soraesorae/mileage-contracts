// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SwMileageToken} from "../src/SwMileageToken.sol";
import {SwMileageTokenFactory} from "../src/SwMileageFactory.sol";

interface Ownable {
    function owner() external view returns (address);
}

contract SwMileageFactoryTest is Test {
    // SwMileageToken public mileageToken;
    SwMileageTokenFactory public factory;
    address alice = makeAddr("alice");

    function setUp() public {
        vm.prank(alice);
        factory = new SwMileageTokenFactory();
        console.log(address(this));
        console.log(address(factory));
    }

    function test_deploy() public {
        vm.prank(alice);
        SwMileageToken deployed = SwMileageToken(factory.deploy("SwMileageToken", "SMT"));
        console.log(address(deployed));
        assertEq(deployed.name(), "SwMileageToken");
        assertEq(deployed.symbol(), "SMT");
        assertEq(deployed.isAdmin(alice), true);
    }
}
