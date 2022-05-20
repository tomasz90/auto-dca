pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@aave/periphery-v3/contracts/rewards/interfaces/IRewardsController.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";

contract Claimer is KeeperCompatibleInterface, Ownable {

    uint public counter;
    uint public immutable interval;
    uint public lastTimeStamp;
    IRewardsController public immutable rewardsController;
    IPoolAddressesProvider public immutable poolAddressesProvider;

    constructor(uint _interval, address _poolAddressProviderAddress, address _rewardsControllerAddress) {
      interval = _interval;
      lastTimeStamp = block.timestamp;
      counter = 0;
      rewardsController = IRewardsController(_rewardsControllerAddress);
      poolAddressesProvider = IPoolAddressesProvider(_poolAddressProviderAddress);
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
        IPool pool = poolAddressesProvider.getPool();
        address[] memory reserves = pool.getReservesList();
        rewardsController.claimAllRewardsOnBehalf(reserves, owner(), owner());
    }
}
