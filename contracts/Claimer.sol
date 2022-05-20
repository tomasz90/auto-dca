pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@aave/periphery-v3/contracts/rewards/interfaces/IRewardsController.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";

contract Claimer is KeeperCompatibleInterface, Ownable {
    uint256 public counter;
    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    IRewardsController public immutable rewardsController;
    IPoolAddressesProvider public immutable poolAddressesProvider;
    IUniswapV3Pool public immutable pool;

    constructor(
        uint256 _interval,
        address _poolAddressProviderAddress,
        address _rewardsControllerAddress,
        address _uniswapV3Pool
    ) {
        interval = _interval;
        lastTimeStamp = block.timestamp;
        counter = 0;
        rewardsController = IRewardsController(_rewardsControllerAddress);
        pool = IUniswapV3Pool(_uniswapV3Pool);
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata performData) external override {
        IPool aavePool = poolAddressesProvider.getPool();
        address[] memory reserves = aavePool.getReservesList();
        (address[] memory rewardsList, uint256[] memory claimedAmounts)
         = rewardsController.claimAllRewardsOnBehalf(reserves, owner(), owner());
         
        pool.swap(owner(), )
}
