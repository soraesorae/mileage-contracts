// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "kaia-contracts/contracts/access/Ownable.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";
import {IAdmin} from "./IAdmin.sol";

interface ISwMileageTokenImpl is IAdmin {
    function initialize(string memory name_, string memory symbol_, address admin) external;
}

contract SwMileageTokenFactory {
    using Clones for address;

    address private _implementation;

    event MileageTokenCreated(address indexed tokenAddress);

    constructor(
        address impl
    ) {
        _implementation = impl;
    }

    function implementaion() external view returns (address) {
        return _implementation;
    }

    function setImplementation(
        address impl
    ) external {
        _implementation = impl;
    }

    function deploy(string memory name, string memory symbol) external returns (address) {
        address clone = _implementation.clone();
        ISwMileageTokenImpl(clone).initialize(name, symbol, msg.sender);
        emit MileageTokenCreated(clone);
        return address(clone);
    }
}
