// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {KIP7} from "kaia-contracts/contracts/KIP/token/KIP7/KIP7.sol";
import {IKIP7} from "kaia-contracts/contracts/KIP/token/KIP7/IKIP7.sol";
import {KIP7Burnable} from "kaia-contracts/contracts/KIP/token/KIP7/extensions/KIP7Burnable.sol";
import {Pausable} from "kaia-contracts/contracts/security/Pausable.sol";
import {OwnableMulti} from "./OwnableMulti.sol";
import {Context} from "kaia-contracts/contracts/utils/Context.sol";

import {SortedList} from "./SortedList.sol";
import {ISwMileageToken} from "./ISwMileageToken.sol";

// TODO: new contract for multiple owner instead of `Ownable`
contract SwMileageToken is Context, IKIP7, KIP7, KIP7Burnable, Pausable, OwnableMulti, SortedList {
    struct Student {
        address wallet;
        uint256 balance;
    }
    /// @dev contract constructor
    /// set KIP7 token name, symbol
    ///
    /// @param name_ token name
    /// @param symbol_ token symbol

    // constructor(string memory name_, string memory symbol_) KIP7(name_, symbol_) {}
    constructor(string memory name_, string memory symbol_) KIP7(name_, symbol_) {}

    function decimals() public view override returns (uint8) {
        return 0;
    }

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

    function burn(uint256 amount) public override onlyOwner {}

    /// @dev KIP7Burnable burnFrom
    /// bypass allowance check when msg.sender is owner
    /// @param account target account
    /// @param amount amount
    function burnFrom(address account, uint256 amount) public override onlyOwner whenNotPaused {
        // if (_msgSender() != owner()) {
        //     _spendAllowance(account, _msgSender(), amount);
        // }
        _burn(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 /*amount*/ ) internal pure override {
        require(from == address(0) || to == address(0), "only mint or burn");
    }

    // check is secure
    function _afterTokenTransfer(address from, address to, uint256 /*amount*/ ) internal override {
        // TODO _update(..., INC) _update(..., DEC)
        require(from == address(0) || to == address(0));
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
