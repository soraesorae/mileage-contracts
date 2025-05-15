// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SwMileageTokenImpl} from "../src/SwMileageToken.impl.sol";
import {StudentManagerImpl} from "../src/StudentManager.impl.sol";

contract SwMileageDeployScript is Script {
    function setUp() public {}

    function run() public {
        string memory rpcUrl = vm.envString("TEST_RPC_URL");
        uint256 pvKey = vm.envUint("TEST_DEPLOYER_PRIVATE_KEY");
        address account = vm.addr(pvKey);
        StudentManagerImpl manager = StudentManagerImpl(vm.envAddress("TEST_MANAGER_ADDRESS"));

        console.log("RPC URL: ", rpcUrl);

        bytes32 studentId = keccak256(abi.encode("STUDENT1"));
        bytes32 docHash = keccak256(abi.encode("DOCUMENT1"));
        bytes32 reasonHash = keccak256(abi.encode("REASON"));

        vm.createSelectFork(rpcUrl);

        vm.startBroadcast(pvKey);

        manager.registerStudent(studentId);

        uint256 index = manager.submitDocument(docHash);

        manager.approveDocument(index, 100, reasonHash);

        vm.stopBroadcast();

        console.log(SwMileageTokenImpl(manager.mileageToken()).balanceOf(account));
    }
}
