// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20Mock {

    uint256 _allowance;
    uint256 _balance;

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowance;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balance;
    }

    function setAllowance(uint256 allowance) external {
        _allowance = allowance;
    }

    function setBalance(uint256 balance) external {
        _balance = balance;
    }
}
