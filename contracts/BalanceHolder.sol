// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./AutoDca.sol";
import "./IOps.sol";

contract BalanceHolder {
    address public immutable manager;
    IOps public immutable ops;

    mapping(address => uint256) public balances;

    modifier onlyManager() {
        require(msg.sender == manager, "Caller is not the autoDca");
        _;
    }

    constructor(
        address _manager,
        address _autoDca,
        IOps _ops
    ) {
        manager = _manager;
        ops = _ops;
        setUpTask(_autoDca, _ops);
    }

    function setUpTask(address _autoDca, IOps _ops) private {
        _ops.createTask(_autoDca, AutoDca.exec.selector, _autoDca, abi.encodeWithSelector(AutoDca.checker.selector));
    }

    function deposit(address user) external payable onlyManager {
        balances[user] += msg.value;
        payable(ops.taskTreasury()).transfer(msg.value);
    }

    function deductSwapBalance(address user, uint256 cost) external onlyManager {
        balances[user] -= cost;
    }
}
