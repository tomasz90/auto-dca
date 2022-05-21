pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract AutoDca is KeeperCompatibleInterface, Ownable {
    uint256 public counter;
    uint256 public immutable interval;
    uint256 public lastTimeStamp;

    uint256 public amount;

    IERC20 public immutable stableToken;
    IERC20 public immutable dcaIntoToken;

    uint24 public poolFee;

    ISwapRouter uniswapRouter;

    address public keeperRegistryAddress;

    event KeeperRegistryAddressUpdated(address oldAddress, address newAddress);
    event AmountUpdated(uint256 oldAmount, uint256 newAmount);

    constructor(
        uint256 _interval,
        uint256 _amount,
        IERC20 _stableToken,
        IERC20 _dcaIntoToken,
        IUniswapV3Factory _uniswapFactory,
        ISwapRouter _uniswapRouter
    ) {
        interval = _interval;
        lastTimeStamp = block.timestamp;
        counter = 0;
        amount = _amount;
        stableToken = _stableToken;
        dcaIntoToken = _dcaIntoToken;
        poolFee = findPoolFee(_uniswapFactory, _stableToken, _dcaIntoToken);
        uniswapRouter = _uniswapRouter;
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
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata performData) external onlyKeeperRegistry override {
        stableToken.transferFrom(owner(), address(this), amount);
        stableToken.approve(address(uniswapRouter), amount);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(stableToken),
                tokenOut: address(dcaIntoToken),
                fee: poolFee,
                recipient: owner(),
                deadline: block.timestamp + 60,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        uniswapRouter.exactInputSingle(params);
    }

    function findPoolFee(
        IUniswapV3Factory _uniswapFactory,
        IERC20 _stableToken,
        IERC20 _dcaIntoToken
    ) private view returns (uint24) {
        uint24[3] memory fee = [uint24(100), uint24(500), uint24(3000)];
        for (uint256 i; i < fee.length; i++) {
            address poolAddress = _uniswapFactory.getPool(
                address(_stableToken),
                address(_dcaIntoToken),
                fee[i]
            );
            if (poolAddress != address(0)) {
                return fee[i];
            }
        }
    }

    function setKeeperRegistryAddress(address _keeperRegistryAddress) external onlyOwner {
        emit KeeperRegistryAddressUpdated(keeperRegistryAddress, _keeperRegistryAddress);
        keeperRegistryAddress = _keeperRegistryAddress;
    }

    function setAmount(uint _amount) external onlyOwner {
        emit AmountUpdated(amount, _amount);
        amount = _amount;
    }
}
