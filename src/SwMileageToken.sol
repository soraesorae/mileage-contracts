// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {KIP7} from "kaia-contracts/contracts/KIP/token/KIP7/KIP7.sol";
import {IKIP7} from "kaia-contracts/contracts/KIP/token/KIP7/IKIP7.sol";
import {KIP7Burnable} from "kaia-contracts/contracts/KIP/token/KIP7/extensions/KIP7Burnable.sol";
import {Pausable} from "kaia-contracts/contracts/security/Pausable.sol";
import {Ownable} from "kaia-contracts/contracts/access/Ownable.sol";
import {Context} from "kaia-contracts/contracts/utils/Context.sol";

// TODO: new contract for multiple owner instead of `Ownable`
contract SwMaileageToken is Context, IKIP7, KIP7, KIP7Burnable, Pausable, Ownable {
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

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev mint mileage token
     *
     * @param _account `to` account
     * @param _amount token amount
     */
    function mint(address _account, uint256 _amount) public onlyOwner whenNotPaused {
        _mint(_account, _amount);
    }

    // // only one owner
    // function setAllowancesMax(address _account) public onlyOwner {
    //     _approve(_account, owner, type(uint256).max);
    // }

    /**
     * @dev KIP7Burnable burnFrom
     * bypass allowance check when msg.sender is owner
     * @param account target account
     * @param amount amount
     */
    function burnFrom(address account, uint256 amount) public override whenNotPaused {
        if (_msgSender() != owner()) {
            _spendAllowance(account, _msgSender(), amount);
        }
        _burn(account, amount);
    }
}
