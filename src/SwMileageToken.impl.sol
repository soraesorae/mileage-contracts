// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {KIP7} from "kaia-contracts/contracts/KIP/token/KIP7/KIP7.sol";
import {IKIP7} from "kaia-contracts/contracts/KIP/token/KIP7/IKIP7.sol";
import {KIP7Burnable} from "kaia-contracts/contracts/KIP/token/KIP7/extensions/KIP7Burnable.sol";
import {IKIP7Burnable} from "kaia-contracts/contracts/KIP/token/KIP7/extensions/IKIP7Burnable.sol";
import {Admin} from "./Admin.sol";
import {Initializable} from "kaia-contracts/contracts/proxy/utils/Initializable.sol";
import {Context} from "kaia-contracts/contracts/utils/Context.sol";

import {SortedList} from "./SortedList.sol";
import {ISortedList} from "./ISortedList.sol";
import {ISwMileageToken} from "./ISwMileageToken.sol";

// TODO: new contract for multiple owner instead of `Ownable`
contract SwMileageTokenImpl is Context, ISwMileageToken, KIP7Burnable, Initializable, Admin, ISortedList, SortedList {
    string private _name;
    string private _symbol;

    /// @dev contract constructor
    /// set KIP7 token name, symbol
    ///
    constructor(string memory name_, string memory symbol_) KIP7(name_, symbol_) {}

    function initialize(string memory name_, string memory symbol_, address admin) external initializer {
        _name = name_;
        _symbol = symbol_;
        _addAdmin(admin);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    /// @dev satisfy KIP13
    ///
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @dev mint mileage token
    ///
    /// @param account `to` account
    /// @param amount token amount
    ///
    function mint(address account, uint256 amount) public onlyAdmin {
        _mint(account, amount);
    }

    /// @dev prevent token holders to destory their own tokens
    ///
    function burn(
        uint256 /* amount */
    ) public pure override (IKIP7Burnable, KIP7Burnable) {
        require(false, "burn not allowed");
    }
    ////

    function _approve(address, /* owner */ address, /* spender */ uint256 /* amount */ ) internal pure override {
        require(false, "approval not allowed");
    }

    /// @dev KIP7Burnable burnFrom
    /// bypass allowance check when msg.sender is owner
    ///
    /// @param account target account
    /// @param amount amount
    ///
    function burnFrom(address account, uint256 amount) public override (IKIP7Burnable, KIP7Burnable) onlyAdmin {
        _burn(account, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override (IKIP7, KIP7) onlyAdmin returns (bool) {
        _transfer(from, to, amount);
        return true;
    }

    function _beforeTokenTransfer(address, address, uint256) internal view override {
        require(isAdmin(msg.sender), "admin only");
    }

    function _afterTokenTransfer(address from, address to, uint256 /* amount */ ) internal virtual override {
        // require(from == address(0) || to == address(0));
        // increase decrease
        if (from == address(0)) {
            // mint
            _updateElement(to, balanceOf(to));
        } else if (to == address(0)) {
            // burn
            uint256 balance = balanceOf(from);
            if (balance != 0) {
                _updateElement(from, balance);
            } else {
                _removeElement(from, true);
            }
        } else {
            // transferFrom
            uint256 fromBalance = balanceOf(from);
            uint256 toBalance = balanceOf(to);
            if (fromBalance != 0) {
                _updateElement(from, fromBalance);
                _updateElement(to, toBalance);
            } else {
                _removeElement(from, false);
                _updateElement(to, toBalance);
            }
        }
    }

    function getRankingRange(uint256 from, uint256 to) external view returns (Student[] memory) {
        return abi.decode(_getElementRange(from, to), (Student[]));
    }
}
