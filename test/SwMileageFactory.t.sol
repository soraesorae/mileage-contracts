// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SwMileageTokenImpl} from "../src/SwMileageToken.impl.sol";
import {StudentManagerImpl} from "../src/StudentManager.impl.sol";
import {SwMileageTokenFactory} from "../src/SwMileageFactory.sol";
import {StudentManagerFactory} from "../src/StudentManagerFactory.sol";

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
        impl = new SwMileageTokenImpl("", "");
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

    function test_deployWithAdmin() public {
        address dummy = makeAddr("dummy");
        vm.prank(alice);
        SwMileageTokenImpl deployed =
            SwMileageTokenImpl(factory.deployWithAdmin("SwMileageToken2025", "SMT2025", dummy));
        assertEq(deployed.name(), "SwMileageToken2025");
        assertEq(deployed.symbol(), "SMT2025");
        assertEq(deployed.isAdmin(dummy), true);
    }

    function test_deployWithAdmin_studentManager() public {
        vm.startPrank(alice);
        StudentManagerImpl studentManagerImpl = new StudentManagerImpl(address(0));
        StudentManagerFactory studentManagerFactory = new StudentManagerFactory(address(studentManagerImpl));
        StudentManagerImpl dummyManager = StudentManagerImpl(studentManagerFactory.deploy(address(0)));
        vm.stopPrank();

        vm.prank(alice);
        SwMileageTokenImpl deployed =
            SwMileageTokenImpl(factory.deployWithAdmin("SwMileageToken2025", "SMT2025", address(dummyManager)));
        assertEq(deployed.name(), "SwMileageToken2025");
        assertEq(deployed.symbol(), "SMT2025");
        assertEq(deployed.isAdmin(address(dummyManager)), true);

        vm.prank(alice);
        dummyManager.changeMileageToken(address(deployed));

        address bob = makeAddr("bob");

        bytes32 studentId = keccak256(abi.encodePacked("student1"));
        bytes32 docHash = keccak256(abi.encodePacked("doc"));
        bytes32 reason = keccak256(abi.encodePacked("reason"));

        vm.prank(bob);
        dummyManager.registerStudent(studentId);

        vm.prank(bob);
        dummyManager.submitDocument(docHash);

        vm.prank(alice);
        dummyManager.approveDocument(0, 100, reason);

        assertEq(deployed.balanceOf(bob), 100);
    }
}
