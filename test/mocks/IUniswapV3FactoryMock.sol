// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

contract IUniswapV3FactoryMock {
    
    function getPool(address token0, address token1, uint24 fee) public view returns(address) {
        return 0x0000000000000000000000000000000000000001;
    }
}