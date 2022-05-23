// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IERC20Mock {
    function allowance(address owner, address spender) external view returns (uint256) {
        if (owner == 0xd329365f5D1921B5cC04c91Ede020b92236B3264) {
            return 10000;
        }
    }

    function balanceOf(address account) external view returns (uint256) {
        if (account == 0xd329365f5D1921B5cC04c91Ede020b92236B3264) {
            return 10000;
        }
    }
}
