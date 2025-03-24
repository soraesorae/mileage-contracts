// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {KIP7} from "kaia-contracts/contracts/KIP/token/KIP7/KIP7.sol";
import {IKIP7} from "kaia-contracts/contracts/KIP/token/KIP7/IKIP7.sol";
import {KIP7Burnable} from "kaia-contracts/contracts/KIP/token/KIP7/extensions/KIP7Burnable.sol";
import {Pausable} from "kaia-contracts/contracts/security/Pausable.sol";
import {Admin} from "./Admin.sol";
import {Initializable} from "kaia-contracts/contracts/proxy/utils/Initializable.sol";
import {Context} from "kaia-contracts/contracts/utils/Context.sol";

import {SortedList} from "./SortedList.sol";
import {ISwMileageToken} from "./ISwMileageToken.sol";

// TODO: new contract for multiple owner instead of `Ownable`
contract SwMileageTokenImpl is Context, IKIP7, KIP7, KIP7Burnable, Initializable, Pausable, Admin, SortedList {
    string private _name;
    string private _symbol;

    struct Student {
        address account;
        uint256 balance;
    }

    /// @dev contract constructor
    /// set KIP7 token name, symbol
    ///
    constructor() KIP7("SwMileageToken", "SMT") {}

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
    ) public view virtual override (KIP7, KIP7Burnable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    /// @dev mint mileage token
    ///
    /// @param account `to` account
    /// @param amount token amount
    ///
    function mint(address account, uint256 amount) public onlyAdmin whenNotPaused {
        _mint(account, amount);
    }

    /// @dev prevent token holders to destory their own tokens
    ///
    function burn(
        uint256 /* amount */
    ) public pure override {
        require(false, "Blocked");
    }
    ////

    function _approve(address, /* owner */ address, /* spender */ uint256 /* amount */ ) internal pure override {
        require(false, "Blocked");
    }

    function _transfer(address, /* from */ address, /* to */ uint256 /* amount */ ) internal pure override {
        require(false, "Blocked");
    }

    /// @dev KIP7Burnable burnFrom
    /// bypass allowance check when msg.sender is owner
    ///
    /// @param account target account
    /// @param amount amount
    ///
    function burnFrom(address account, uint256 amount) public override onlyAdmin whenNotPaused {
        // if (_msgSender() != owner()) {
        //     _spendAllowance(account, _msgSender(), amount);
        // }
        _burn(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 /*amount*/ ) internal pure override {
        require(from == address(0) || to == address(0), "only mint or burn");
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
                _removeElement(from);
            }
        }
    }

    function getRankingRange(uint256 from, uint256 to) external view returns (Student[] memory) {
        return abi.decode(_getElementRange(from, to), (Student[]));
    }
}
