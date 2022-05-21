// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract AutoDca is KeeperCompatibleInterface, Pausable, Ownable {

    uint256 public counter;
    uint256 public lastTimeStamp;
    uint256 public interval;

    uint256 public amount;

    IERC20 public stableToken;
    IERC20 public dcaIntoToken;

    IUniswapV3Factory uniswapFactory;

    address public keeperRegistryAddress;

    event KeeperRegistryAddressUpdated(address oldAddress, address newAddress);
    event AmountUpdated(uint256 oldAmount, uint256 newAmount);

    constructor(
        uint256 _interval,
        uint256 _amount,
        IERC20 _stableToken,
        IERC20 _dcaIntoToken,
        IUniswapV3Factory _uniswapFactory,
        address _keeperRegistryAddress
    ) {
        interval = _interval;
        lastTimeStamp = block.timestamp;
        counter = 0;

        amount = _amount;

        stableToken = _stableToken;
        dcaIntoToken = _dcaIntoToken;

        uniswapFactory = _uniswapFactory;
        keeperRegistryAddress = _keeperRegistryAddress;
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
        if(paused()) {
            return(false, performData);
        }

        uint256 balance = stableToken.balanceOf(address(this));

        if(balance < amount) {
            return(false, performData);
        }

        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata performData) external override onlyKeeperRegistry whenNotPaused {
        counter++;
        lastTimeStamp = block.timestamp;
        
        uint256 balance = stableToken.balanceOf(address(this));
        require(balance >= amount, "Not enough funds");

        IUniswapV3Pool pool = findPool();

        stableToken.approve(address(pool), amount);

        bool zeroForOne = address(stableToken) < address(dcaIntoToken);

        pool.swap(address(this), zeroForOne, int256(amount), 0, "");

    }

    function setKeeperRegistryAddress(address _keeperRegistryAddress) external onlyOwner {
        emit KeeperRegistryAddressUpdated(keeperRegistryAddress, _keeperRegistryAddress);
        keeperRegistryAddress = _keeperRegistryAddress;
    }

    function setAmount(uint256 _amount) external onlyOwner {
        emit AmountUpdated(amount, _amount);
        amount = _amount;
    }

    function setInterval(uint256 _interval) external onlyOwner {
        interval = _interval;
    }

    function setStableToken(IERC20 _token) public onlyOwner {
        stableToken = _token;
    }

    function setDcaIntoToken(IERC20 _token) public onlyOwner {
        dcaIntoToken = _token;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner(), balance);
    }

    function findPool() private returns (IUniswapV3Pool) {
        uint24[3] memory fee = [uint24(100), uint24(500), uint24(3000)];
        for (uint256 i; i < fee.length; i++) {
            address poolAddress = uniswapFactory.getPool(
                address(stableToken),
                address(dcaIntoToken),
                fee[i]
            );
            if (poolAddress != address(0)) {
                return IUniswapV3Pool(poolAddress);
            }
        }

        _pause(); // pause upkeep, there is no sense to perform upkeeps when swap cannot be done

        string memory message = string(
            abi.encodePacked("No pool with tokens: ", 
            address(stableToken), 
            ", ", 
            address(dcaIntoToken)));

        revert(message);
    }
}
