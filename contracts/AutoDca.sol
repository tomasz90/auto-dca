// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "./AccountManager.sol";

contract AutoDca is KeeperCompatibleInterface, Ownable {

    uint256 public counter;
    address public keeperRegistryAddress;
    AccountManager public immutable manager;

    event KeeperRegistryAddressUpdated(address oldAddress, address newAddress);
    event AmountUpdated(uint256 oldAmount, uint256 newAmount);

    constructor(
        IUniswapV3Factory _uniswapFactory,
        address _keeperRegistryAddress
    ) {
        counter = 0;
        keeperRegistryAddress = _keeperRegistryAddress;
        manager = new AccountManager(_uniswapFactory, address(this));
    }

    modifier onlyKeeperRegistry() {
        require(msg.sender == keeperRegistryAddress, "Caller is not the keeper registry");
        _;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {   
        address user = manager.getUserNeedKeepUp();
        if(upkeepNeeded = user != address(0)) {
            performData = abi.encode(user);
        }
    }

    function performUpkeep(bytes calldata performData) external override onlyKeeperRegistry {
        address user = abi.decode(performData, (address));
        counter++;
        manager.setUserNextKeepUp(user);
        (IUniswapV3Pool pool, IERC20 stableToken, IERC20 dcaIntoToken, uint256 amount)
            = manager.getSwapParams(user);
        swap(user, pool, stableToken, dcaIntoToken, amount);
    }

    function setKeeperRegistryAddress(address _keeperRegistryAddress) external onlyOwner {
        emit KeeperRegistryAddressUpdated(keeperRegistryAddress, _keeperRegistryAddress);
        keeperRegistryAddress = _keeperRegistryAddress;
    }

    function swap(address user, IUniswapV3Pool pool, IERC20 stableToken, IERC20 dcaIntoToken, uint256 amount) private {
        uint256 balance = stableToken.balanceOf(address(this));
        require(balance >= amount, "Not enough funds");

        stableToken.approve(address(pool), amount);

        bool zeroForOne = address(stableToken) < address(dcaIntoToken);

        pool.swap(user, zeroForOne, int256(amount), 0, "");
    }
}
