// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "./AccountManager.sol";

contract AutoDca is Ownable {

    uint256 public counter;
    AccountManager public immutable manager;
    ISwapRouter router;
    address public immutable ops;

    constructor(
        IUniswapV3Factory _uniswapFactory,
        ISwapRouter _router,
        address _ops 
    ) {
        counter = 0;
        router = _router;
        ops = _ops;
        manager = new AccountManager(_uniswapFactory, address(this));
    }

    modifier onlyExecutor() {
        if(msg.sender != ops) {
            string memory sender = Strings.toHexString(uint256(uint160(msg.sender)), 20);
            string memory message = string(abi.encodePacked("Sender is not an Executor: ", sender));
            revert(message);
        }
        _;
    }

    modifier onlyInRightTime(bytes memory execPayload) {
        address user = abi.decode(execPayload, (address));
        require(manager.isExecTime(user), "Require right time for calling");
        _;
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {   
        address user = manager.getUserNeedExec();
        if(user != address(0)) {
            canExec = true;
            bytes memory payload = abi.encode(user);
            execPayload = abi.encodeWithSelector(AutoDca.exec.selector, payload);
        }
    }

    function exec(bytes calldata execPayload) external onlyExecutor onlyInRightTime(execPayload) {
        address user = abi.decode(execPayload, (address));
        counter++;
        manager.setUserNextExec(user);
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
