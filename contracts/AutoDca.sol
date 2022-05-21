// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract AutoDca is KeeperCompatibleInterface, Ownable {

    uint256 public counter;

    IUniswapV3Factory uniswapFactory;

    address public keeperRegistryAddress;

    mapping(address => AccountParams) public accountsParams;
    address[] public accounts;

    event KeeperRegistryAddressUpdated(address oldAddress, address newAddress);
    event AmountUpdated(uint256 oldAmount, uint256 newAmount);

    struct AccountParams {
        uint256 interval;
        uint256 actionTime;
        uint256 amount;
        IERC20 stableToken;
        IERC20 dcaIntoToken;
        bool paused;
    }

    constructor(
        IUniswapV3Factory _uniswapFactory,
        address _keeperRegistryAddress
    ) {
        counter = 0;
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

        for(uint i; i < accounts.length; i++) {
            AccountParams memory account = accountsParams[accounts[i]];
            uint256 actionTime = account.actionTime;
            bool spendable = spendable(accounts[i], account.stableToken, account.amount);
            if(actionTime < block.timestamp && spendable) {
                upkeepNeeded = true;
                performData = abi.encode(accounts[i]);
            }
        }
    }

    function performUpkeep(bytes calldata performData) external override onlyKeeperRegistry {
        counter++;
        address user = abi.decode(performData, (address));
        swap(user, accountsParams[user]);
    }

    function setKeeperRegistryAddress(address _keeperRegistryAddress) external onlyOwner {
        emit KeeperRegistryAddressUpdated(keeperRegistryAddress, _keeperRegistryAddress);
        keeperRegistryAddress = _keeperRegistryAddress;
    }

    function setUpAccount(uint256 _interval, uint256 _amount, IERC20 _stableToken, IERC20 _dcaIntoToken) external {
        AccountParams memory params = AccountParams(
            _interval,
            block.timestamp + _interval,
            _amount,
            _stableToken,
            _dcaIntoToken,
            false
        );
        accountsParams[msg.sender] = params;
        accounts.push(msg.sender);
    }

    function swap(address user, AccountParams memory params) private {
        uint256 balance = params.stableToken.balanceOf(address(this));
        require(balance >= params.amount, "Not enough funds");

        IUniswapV3Pool pool = findPool(user, params.stableToken, params.dcaIntoToken);

        params.stableToken.approve(address(pool), params.amount);

        bool zeroForOne = address(params.stableToken) < address(params.dcaIntoToken);

        pool.swap(address(this), zeroForOne, int256(params.amount), 0, "");
    }

    function spendable(address user, IERC20 stableToken, uint256 amount) private view returns(bool) {
        uint256 allowance = stableToken.allowance(user, address(this));
        return stableToken.balanceOf(user) > amount
            && allowance > amount;
    }

    function findPool(address user, IERC20 stableToken, IERC20 dcaIntoToken) private returns (IUniswapV3Pool) {
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

         // there is no sense to perform upkeeps when swap cannot be done
        accountsParams[user].paused = true;

        string memory message = string(
            abi.encodePacked("No pool with tokens: ", 
            address(stableToken), 
            ", ", 
            address(dcaIntoToken)));

        revert(message);
    }
}
