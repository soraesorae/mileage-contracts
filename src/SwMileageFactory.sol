// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SwMileageToken} from "./SwMileageToken.sol";

// https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Factory.sol
contract SwMileageTokenFactory {
    event MileageTokenCreated(address token);

    constructor() {}

    function deploy(string memory _name, string memory _symbol) external returns (address) {
        SwMileageToken token = new SwMileageToken(_name, _symbol);
        token.addOwnership(msg.sender);
        token.removeOwnership(address(this));
        emit MileageTokenCreated(address(token));
        return address(token);
    }
}
