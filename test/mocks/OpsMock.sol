// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract OpsMock {
    address tt;

    function taskTreasury() external returns (address) {
        return tt;
    }

    function createTask(
        address execAddress,
        bytes4 execSelector,
        address resolverAddress,
        bytes calldata resolverData
    ) external returns (bytes32 task) {}

    function setTaskTreasury(address _taskTreasury) external {
        tt = _taskTreasury;
    }
}
