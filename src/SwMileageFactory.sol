// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SwMileageToken} from "./SwMileageToken.sol";

// https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Factory.sol
contract SwMileageTokenFactory {
    event CreateMileageToken(address tokenAddress);

    constructor() {}

<<<<<<< HEAD
    function deploy(string memory _name, string memory _symbol) external returns (address) {
        SwMileageToken token = new SwMileageToken(_name, _symbol);
        token.addOwnership(msg.sender);
        token.removeOwnership(address(this));
        emit MileageTokenCreated(address(token));
        return address(token);
=======
    function deploy(string memory name, string memory symbol) external returns (address) {
        SwMileageToken mileageToken = new SwMileageToken(name, symbol);
        mileageToken.addAdmin(msg.sender);
        mileageToken.removeAdmin(address(this));
        emit CreateMileageToken(address(mileageToken));
        return address(mileageToken);
>>>>>>> 8edc740 (Refactor factory contarct)
    }
}
