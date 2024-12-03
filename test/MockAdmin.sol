// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Admin} from "../src/Admin.sol";

contract MockAdmin is Admin {
    function checkAdmin() public onlyAdmin {}
}
