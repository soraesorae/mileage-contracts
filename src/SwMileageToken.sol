// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {KIP7} from "kaia-contracts/contracts/KIP/token/KIP7/KIP7.sol";
import {IKIP7} from "kaia-contracts/contracts/KIP/token/KIP7/IKIP7.sol";
import {KIP7Burnable} from "kaia-contracts/contracts/KIP/token/KIP7/extensions/KIP7Burnable.sol";
import {Pausable} from "kaia-contracts/contracts/security/Pausable.sol";
import {Ownable} from "kaia-contracts/contracts/access/Ownable.sol";

contract SwMaileageToken is IKIP7, KIP7, KIP7Burnable, Pausable, Ownable {
    /**
     * @dev satisfy KIP13
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(KIP7, KIP7Burnable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev contract constructor
     * set KIP7 token name, symbol
     *
     * @param name_ token name
     * @param symbol_ token symbol
     */
    constructor(string memory name_, string memory symbol_) KIP7(name_, symbol_) {}
}
