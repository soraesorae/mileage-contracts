// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SwMileageTokenImpl} from "../src/SwMileageToken.impl.sol";
import {SwMileageTokenFactory} from "../src/SwMileageFactory.sol";
import {StudentManagerImpl} from "../src/StudentManager.impl.sol";
import {StudentManagerFactory} from "../src/StudentManagerFactory.sol";

interface IStudentManagerFactory {
    event StudentManagerCreated(address indexed contractAddress);
}

contract StudentManagerFactoryTest is Test {
    StudentManagerImpl public impl;
    StudentManagerFactory public factory;
    SwMileageTokenImpl public mileageToken;
    SwMileageTokenFactory public tokenFactory;

    address alice = makeAddr("alice");

    function setUp() public {
        vm.startPrank(alice);

        mileageToken = new SwMileageTokenImpl("TokenAlice", "TALI");

        impl = new StudentManagerImpl(address(mileageToken));
        factory = new StudentManagerFactory(address(impl));
        SwMileageTokenImpl tokenImpl = new SwMileageTokenImpl("TokenBobImpl", "TBOB");
        tokenFactory = new SwMileageTokenFactory(address(tokenImpl));
    }

    function test_deploy() public {
        StudentManagerImpl deployed = StudentManagerImpl(factory.deploy(address(mileageToken)));
        assertEq(deployed.mileageToken(), address(mileageToken));
        assertTrue(deployed.isAdmin(alice));

        SwMileageTokenImpl next = new SwMileageTokenImpl("TokenCharlie", "TCHA");
        deployed.changeMileageToken(address(next));
        assertEq(deployed.mileageToken(), address(next));
    }

    // test emit event with predicted address

    function test_deploy_tokenFactory() public {
        SwMileageTokenImpl deployedToken = SwMileageTokenImpl(tokenFactory.deploy("TokenAlpha", "TALP"));
        assertEq(deployedToken.name(), "TokenAlpha");
        assertEq(deployedToken.symbol(), "TALP");

        StudentManagerImpl deployedManager = StudentManagerImpl(factory.deploy(address(deployedToken)));
        address bob = makeAddr("bob");
        deployedManager.addAdmin(bob);

        assertEq(deployedManager.mileageToken(), address(deployedToken));
        assertTrue(deployedManager.isAdmin(alice));
        assertTrue(deployedManager.isAdmin(bob));
    }
}
