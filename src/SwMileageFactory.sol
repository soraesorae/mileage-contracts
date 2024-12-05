// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "kaia-contracts/contracts/access/Ownable.sol";
import {SwMileageToken} from "./SwMileageToken.sol";

// https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Factory.sol
contract SwMileageTokenFactory {
    event MileageTokenCreated(address indexed tokenAddress);

    constructor() {}

    function deploy(string memory name, string memory symbol) external returns (address) {
        SwMileageToken mileageToken = new SwMileageToken(name, symbol);
        mileageToken.addAdmin(msg.sender);
        mileageToken.removeAdmin(address(this));
        emit MileageTokenCreated(address(mileageToken));
        return address(mileageToken);
    }
}
