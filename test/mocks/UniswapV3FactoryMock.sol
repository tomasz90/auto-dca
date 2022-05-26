// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

contract UniswapV3FactoryMock {
    address pool;

    function getPool(
        address token0,
        address token1,
        uint24 fee
    ) public view returns (address) {
        return pool;
    }

    function setPool(address _pool) external {
        pool = _pool;
    }
}
