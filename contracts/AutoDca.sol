// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "./AccountManager.sol";

contract AutoDca is Ownable {

    uint256 public counter;
    address public executorAddress;
    AccountManager public immutable manager;

    event ExecutorAddressUpdated(address oldAddress, address newAddress);
    event AmountUpdated(uint256 oldAmount, uint256 newAmount);

    constructor(
        IUniswapV3Factory _uniswapFactory,
        address _executorAddress
    ) {
        counter = 0;
        executorAddress = _executorAddress;
        manager = new AccountManager(_uniswapFactory, address(this));
    }

    modifier onlyKeeperRegistry() {
        require(msg.sender == executorAddress, "Caller is not the keeper registry");
        _;
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {   
        address user = manager.getUserNeedKeepUp();
        if(canExec = user != address(0)) {
            execPayload = abi.encodeWithSelector(AutoDca.exec.selector, user);
        }
    }

    function exec(bytes calldata execPayload) external {
        address user = abi.decode(execPayload, (address));
        counter++;
        manager.setUserNextKeepUp(user);
        (IUniswapV3Pool pool, IERC20 stableToken, IERC20 dcaIntoToken, uint256 amount)
            = manager.getSwapParams(user);
        swap(user, pool, stableToken, dcaIntoToken, amount);
    }

    function setExecutor(address _executorAddress) external onlyOwner {
        emit ExecutorAddressUpdated(executorAddress, _executorAddress);
        executorAddress = _executorAddress;
    }

    function swap(address user, IUniswapV3Pool pool, IERC20 stableToken, IERC20 dcaIntoToken, uint256 amount) private {
        uint256 balance = stableToken.balanceOf(address(this));
        require(balance >= amount, "Not enough funds");

        stableToken.approve(address(pool), amount);

        bool zeroForOne = address(stableToken) < address(dcaIntoToken);

        pool.swap(user, zeroForOne, int256(amount), 0, "");
    }
}
