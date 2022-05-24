// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "./AccountManager.sol";
import "./IOps.sol";

contract AutoDca {
    uint256 public counter;

    AccountManager public immutable manager;
    ISwapRouter router;
    IOps public immutable ops;

    constructor(
        ISwapRouter _router,
        IUniswapV3Factory _uniswapFactory,
        IOps _ops
    ) {
        counter = 0;
        router = _router;
        ops = _ops;
        manager = new AccountManager(address(this), _uniswapFactory, _ops);
    }

    modifier onlyExecutor() {
        if (msg.sender != address(ops)) {
            string memory sender = Strings.toHexString(uint256(uint160(msg.sender)), 20);
            string memory message = string(abi.encodePacked("Sender is not an Executor: ", sender));
            revert(message);
        }
        _;
    }

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        address user = manager.getUserNeedExec();
        if (user != address(0)) {
            canExec = true;
            execPayload = abi.encodeWithSelector(AutoDca.exec.selector, user);
        }
    }

    function exec(address user) external onlyExecutor {
        uint256 gas = gasleft();
        (, , uint256 amount, uint24 poolFee, IERC20 sellToken, IERC20 buyToken, ) = manager.accountsParams(user);
        require(manager.isExecTime(user), "Require right time for calling");

        counter++;
        manager.setNextExec(user);
        swap(user, poolFee, sellToken, buyToken, amount);

        gas -= gasleft();
        uint256 approxCost = gas * tx.gasprice;
        manager.deductSwapBalance(user, approxCost);
    }

    function swap(
        address user,
        uint24 poolFee,
        IERC20 sellToken,
        IERC20 buyToken,
        uint256 amount
    ) private {
        sellToken.transferFrom(user, address(this), amount);
        sellToken.approve(address(router), amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            address(sellToken),
            address(buyToken),
            poolFee,
            user,
            block.timestamp + 120,
            amount,
            0,
            0
        );

        router.exactInputSingle(params);
    }
}
