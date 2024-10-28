// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

abstract contract BubbleSort {
    address[] private _addr;
    mapping(address => uint256) private _value;

    constructor() {}

    function addDataArray(address[] memory addr_, uint256[] memory value_) internal {
        require(addr_.length == value_.length, "addr.length != value.length");
        for (uint256 i = 0; i < addr_.length; i++) {
            _addr.push(addr_[i]);
            _value[addr_[i]] = value_[i];
        }
    }

    /// @dev bubble sort desc
    /// reference: https://en.wikipedia.org/wiki/Bubble_sort
    ///
    function sort() internal view returns (address[] memory) {
        uint256 n = _addr.length;
        address[] memory sorted = new address[](n);
        for (uint256 i = 0; i < n; i++) {
            sorted[i] = _addr[i];
        }
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (_value[sorted[j]] < _value[sorted[j + 1]]) {
                    (sorted[j], sorted[j + 1]) = (sorted[j + 1], sorted[j]);
                }
            }
        }
        return sorted;
    }
}
