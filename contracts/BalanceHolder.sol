// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./AutoDca.sol";
import "./IOps.sol";
import "./ITaskTreasury.sol";

contract BalanceHolder is Ownable {

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IOps public ops;

    mapping(address => uint256) public balances;

    constructor(address autoDcaAddress, IOps _ops) {
        ops = _ops;
        setUpTask(autoDcaAddress);
    }

    function setUpTask(address autoDcaAddress) private {
        ops.createTask(autoDcaAddress, AutoDca.exec.selector, autoDcaAddress, abi.encodeWithSelector(AutoDca.checker.selector));
    }

    function deposit(address user) external payable onlyOwner {
        balances[user] += msg.value;
        ITaskTreasury taskTreasury = ops.taskTreasury();
        taskTreasury.depositFunds{value: msg.value}(address(this), ETH, msg.value);
    }

    function deductSwapBalance(address user, uint256 cost) external onlyOwner {
        balances[user] -= cost;
    }
}
