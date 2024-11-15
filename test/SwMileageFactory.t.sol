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
    address alice = address(0x1234);

    function setUp() public {
        vm.prank(alice);
        factory = new SwMileageTokenFactory();
        console.log(address(this));
        console.log(address(factory));
    }

    function test_Deploy() public {
        vm.prank(alice);
        SwMileageToken deployed = SwMileageToken(factory.deploy("AAAA", "BBBB"));
        console.log(address(deployed));
        assertEq(deployed.name(), "AAAA");
        assertEq(deployed.symbol(), "BBBB");
        assertEq(deployed.owner(alice), true);
    }
}
