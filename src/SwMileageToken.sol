// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {KIP7} from "kaia-contracts/contracts/KIP/token/KIP7/KIP7.sol";
import {IKIP7} from "kaia-contracts/contracts/KIP/token/KIP7/IKIP7.sol";
import {KIP7Burnable} from "kaia-contracts/contracts/KIP/token/KIP7/extensions/KIP7Burnable.sol";
import {Pausable} from "kaia-contracts/contracts/security/Pausable.sol";
import {Ownable} from "kaia-contracts/contracts/access/Ownable.sol";
import {Context} from "kaia-contracts/contracts/utils/Context.sol";

import {SortedList} from "./SortedList.sol";
import {ISwMileageToken} from "./ISwMileageToken.sol";

// TODO: new contract for multiple owner instead of `Ownable`
contract SwMileageToken is Context, ISwMileageToken, IKIP7, KIP7, KIP7Burnable, Pausable, Ownable, SortedList {
    /// @dev contract constructor
    /// set KIP7 token name, symbol
    ///
    /// @param name_ token name
    /// @param symbol_ token symbol
    constructor(string memory name_, string memory symbol_) KIP7(name_, symbol_) {}

    /// @dev satisfy KIP13
    ///
    function supportsInterface(bytes4 interfaceId) public view virtual override(KIP7, KIP7Burnable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /// @dev mint mileage token
    ///
    /// @param _account `to` account
    /// @param _amount token amount
    function mint(address _account, uint256 _amount) public onlyOwner whenNotPaused {
        _mint(_account, _amount);
    }

    /// @dev KIP7Burnable burnFrom
    /// bypass allowance check when msg.sender is owner
    /// @param account target account
    /// @param amount amount
    function burnFrom(address account, uint256 amount) public override whenNotPaused {
        if (_msgSender() != owner()) {
            _spendAllowance(account, _msgSender(), amount);
        }
        _burn(account, amount);
    }

    // check is secure
    function _afterTokenTransfer(address, /*from*/ address to, uint256 /*amount*/ ) internal override {
        // TODO _update(..., INC) _update(..., DEC)
        uint256 balance = balanceOf(to);
        if (balance == 0) {
            _removeElement(to);
        } else {
            _updateElement(to, balanceOf(to));
        }
        // if (from == address(0)) {
        //      // mint
        //     _updateElement(to, balanceOf(to));
        // } else if (to == address(0)) {
        //     // burn
        // }
    }

    function rankingRange(uint256 from, uint256 to) external view returns (Student[] memory) {
        return abi.decode(_getElementRange(from, to), (Student[]));
    }
}
