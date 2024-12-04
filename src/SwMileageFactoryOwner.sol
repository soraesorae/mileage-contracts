// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "kaia-contracts/contracts/access/Ownable.sol";
import {SwMileageToken} from "./SwMileageToken.sol";

// https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Factory.sol
contract SwMileageTokenFactory is Ownable {
    event MileageTokenCreated(address tokenAddress);

    bool private _on = true;

    modifier on() {
        require(_on, "off");
        _;
    }

    constructor() {}

    function off() external onlyOwner on {
        renounceOwnership();
        _on = false;
    }

    function deploy(string memory name, string memory symbol) external on returns (address) {
        SwMileageToken mileageToken = new SwMileageToken(name, symbol);
        mileageToken.addAdmin(msg.sender);
        mileageToken.removeAdmin(address(this));
        emit MileageTokenCreated(address(mileageToken));
        return address(mileageToken);
    }
}
