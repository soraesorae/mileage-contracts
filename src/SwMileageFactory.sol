// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SwMileageToken} from "./SwMileageToken.sol";

contract SwMileageTokenFactory {
    constructor() {}

    function deploy(string memory _name, string memory _symbol) external returns (address) {
        SwMileageToken token = new SwMileageToken(_name, _symbol);
        // token.transferOwnership(msg.sender);
        token.addOwnership(msg.sender);
        token.removeOwnership(address(this));
        return address(token);
    }
}
