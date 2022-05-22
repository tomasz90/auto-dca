// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "./AccountManager.sol";

contract AutoDca is Ownable {

    uint256 public counter;
    AccountManager public immutable manager;
    ISwapRouter router;

    constructor(
        IUniswapV3Factory _uniswapFactory,
        ISwapRouter _router
    ) {
        counter = 0;
        router = _router;
        manager = new AccountManager(_uniswapFactory, address(this));
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {   
        address user = manager.getUserNeedKeepUp();
        if(user != address(0)) {
            canExec = true;
            execPayload = abi.encodeWithSelector(AutoDca.exec.selector, user);
        }
    }

    function exec(bytes calldata execPayload) external {
        address user = abi.decode(execPayload, (address));
        counter++;
        manager.setUserNextKeepUp(user);
        (uint24 poolFee, IERC20 stableToken, IERC20 dcaIntoToken, uint256 amount)
            = manager.getSwapParams(user);
        swap(user, poolFee, stableToken, dcaIntoToken, amount);
    }

    function swap(address user, uint24 poolFee, IERC20 stableToken, IERC20 dcaIntoToken, uint256 amount) private {
        stableToken.transferFrom(user, address(this), amount);
        stableToken.approve(address(router), amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            address(stableToken),
            address(dcaIntoToken),
            poolFee,
            user,
            block.timestamp + 120,
            100,
            0,
            0
            );

        router.exactInputSingle(params);
    }
}
