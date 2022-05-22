// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "./AccountManager.sol";

contract AutoDca is Ownable {

    bool need;

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {   
        canExec = need;
        execPayload = abi.encodeWithSelector(AutoDca.exec.selector, "");
    }

    function exec(bytes memory execPayload) external {
        need = false;
        address user = 0xd329365f5D1921B5cC04c91Ede020b92236B3264;

        swap(user, 
            ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564), 
            IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984), 
            IERC20(0xc778417E063141139Fce010982780140Aa0cD5Ab), 
            100);
    }

    function setNeed() external {
        need = true;
    }

    function swap(address user, ISwapRouter router, IERC20 stableToken, IERC20 dcaIntoToken, uint256 amount) private {
        stableToken.transferFrom(user, address(this), amount);
        stableToken.approve(address(router), amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            address(stableToken),
            address(dcaIntoToken),
            3000,
            address(this),
            block.timestamp + 120,
            100,
            0,
            0
            );

        router.exactInputSingle(params);
    }
}
