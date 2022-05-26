// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ITaskTreasury.sol";

interface IOps {
    function taskTreasury() external view returns (ITaskTreasury);

    function createTask(
        address execAddress,
        bytes4 execSelector,
        address resolverAddress,
        bytes calldata resolverData
    ) external returns (bytes32 task);
}
