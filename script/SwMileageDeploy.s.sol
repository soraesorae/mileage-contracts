// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
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
        // SwMileageTokenFactory tokenFactory = new SwMileageTokenFactory(address(tokenImpl));

        SwMileageTokenImpl deployedToken = new SwMileageTokenImpl("SwMileageToken", "SMT");

        // console.log("SwMileageTokenFactory deployed to: ", address(tokenFactory));
        console.log("SwMileageToken logic contract deployed to: ", address(tokenImpl));
        console.log("SwMileageToken deployed to: ", address(deployedToken));

        // StudentManagerImpl studentManagerImpl = new StudentManagerImpl(address(0), address(0));
        // StudentManagerFactory managerFactory = new StudentManagerFactory(address(studentManagerImpl));

        // StudentManagerImpl deployedManager =
        //     StudentManagerImpl(managerFactory.deploy(address(deployedToken), address(tokenImpl)));

        StudentManagerImpl deployedManager = new StudentManagerImpl(address(deployedToken), address(tokenImpl));

        deployedToken.addAdmin(address(deployedManager));

        console.log("StudentManager deployed to: ", address(deployedManager));

        // address newToken = deployedManager.deployWithAdmin("SMT", "SMT", address(deployedManager));
        // deployedManager.changeMileageToken(newToken);
        // console.log("New SwMileageToken deployed to: ", newToken);
        // deployedManager.registerStudent(keccak256(abi.encode("STUDENT1")));
        // uint256 index = deployedManager.submitDocument(keccak256(abi.encode("DOCUMENT1")));
        // deployedManager.approveDocument(index, 100, keccak256(abi.encode("REASON")));
        // console.log("Balance: ", SwMileageTokenImpl(newToken).balanceOf(vm.addr(pvKey)));
        vm.stopBroadcast();
    }
}
