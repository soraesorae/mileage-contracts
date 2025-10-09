// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Admin} from "../src/Admin.sol";

contract AdminHarness is Admin {
    function checkAdmin() public onlyAdmin {}
}
