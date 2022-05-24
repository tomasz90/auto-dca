// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOps {
    
    function taskTreasury() external returns (address);

    function createTask(
        address execAddress,
        bytes4 execSelector,
        address resolverAddress,
        bytes calldata resolverData
    ) external returns (bytes32 task);
}
