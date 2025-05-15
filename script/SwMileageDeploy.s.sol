// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SwMileageTokenFactory} from "../src/SwMileageFactory.sol";
import {StudentManagerFactory} from "../src/StudentManagerFactory.sol";
import {SwMileageTokenImpl} from "../src/SwMileageToken.impl.sol";
import {StudentManagerImpl} from "../src/StudentManager.impl.sol";

contract SwMileageDeployScript is Script {
    function setUp() public {}

    function run() public {
        string memory rpcUrl = vm.envString("RPC_URL");
        uint256 pvKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        console.log("RPC URL: ", rpcUrl);

        vm.createSelectFork(rpcUrl);
        vm.startBroadcast(pvKey);

        SwMileageTokenImpl tokenImpl = new SwMileageTokenImpl("", "");
        SwMileageTokenFactory tokenFactory = new SwMileageTokenFactory(address(tokenImpl));

        SwMileageTokenImpl deployedToken = SwMileageTokenImpl(tokenFactory.deploy("SwMileageToken", "SMT"));

        console.log("SwMileageTokenFactory deployed to: ", address(tokenFactory));
        console.log("SwMileageToken logic contract deployed to: ", address(tokenImpl));
        console.log("SwMileageToken deployed to: ", address(deployedToken));

        StudentManagerImpl studentManagerImpl = new StudentManagerImpl(address(0));
        StudentManagerFactory managerFactory = new StudentManagerFactory(address(studentManagerImpl));

        StudentManagerImpl deployedManager = StudentManagerImpl(managerFactory.deploy(address(deployedToken)));

        deployedToken.addAdmin(address(deployedManager));

        console.log("StudentManagerFactory deployed to: ", address(managerFactory));
        console.log("StudentManager logic contract deployed to: ", address(studentManagerImpl));
        console.log("StudentManager deployed to: ", address(deployedManager));

        vm.stopBroadcast();
    }
}
