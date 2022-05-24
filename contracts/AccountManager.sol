// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./AutoDca.sol";
import "./Treasury.sol";
import "./IOps.sol";

contract AccountManager {
    mapping(address => AccountParams) public accountsParams;
    address[] public accounts;

    address public immutable autoDca;
    IOps public immutable ops;
    IUniswapV3Factory public immutable uniswapFactory;
    Treasury public immutable treasury;

    uint256 public constant maxSwapCost = 10**6;

    struct AccountParams {
        uint256 interval;
        uint256 nextExec;
        uint256 amount;
        uint24 poolFee;
        IERC20 stableToken;
        IERC20 dcaIntoToken;
        bool paused;
    }

    modifier onlyAutoDca() {
        require(msg.sender == autoDca, "Caller is not the autoDca");
        _;
    }

    constructor(
        address _autoDca,
        IOps _ops,
        IUniswapV3Factory _uniswapFactory
    ) {
        autoDca = _autoDca;
        ops = _ops;
        uniswapFactory = _uniswapFactory;
        treasury = new Treasury(_autoDca, _ops);
    }

    function setUpAccount(
        uint256 interval,
        uint256 amount,
        IERC20 stableToken,
        IERC20 dcaIntoToken
    ) external payable {
        uint24 poolFee = findPoolFee(stableToken, dcaIntoToken);
        AccountParams memory params = AccountParams(
            interval,
            block.timestamp + interval,
            amount,
            poolFee,
            stableToken,
            dcaIntoToken,
            false
        );
        bool notExists = accountsParams[msg.sender].nextExec == 0;
        if (notExists) {
            accounts.push(msg.sender);
        }
        accountsParams[msg.sender] = params;
        treasury.deposit{value: msg.value}(msg.sender);
    }

    function deductSwapBalance(address user, uint256 cost) external {
        treasury.deductSwapBalance(user, cost);
    }

    function setInterval(uint256 interval) external {
        bool exists = accountsParams[msg.sender].nextExec != 0;
        if (exists) {
            accountsParams[msg.sender].interval = interval;
        } else {
            revert("Account does not exists yet");
        }
    }

    function setAmount(uint256 amount) external {
        bool exists = accountsParams[msg.sender].nextExec != 0;
        if (exists) {
            accountsParams[msg.sender].amount = amount;
        } else {
            revert("Account does not exists yet");
        }
    }

    function setStableToken(IERC20 token) external {
        bool exists = accountsParams[msg.sender].nextExec != 0;
        if (exists) {
            accountsParams[msg.sender].stableToken = token;
        } else {
            revert("Account does not exists yet");
        }
    }

    function setDcaIntoToken(IERC20 token) external {
        bool exists = accountsParams[msg.sender].nextExec != 0;
        if (exists) {
            accountsParams[msg.sender].dcaIntoToken = token;
        } else {
            revert("Account does not exists yet");
        }
    }

    function setNextExec(address user) external onlyAutoDca {
        accountsParams[user].nextExec += accountsParams[user].interval;
    }

    function setPause() external {
        bool exists = accountsParams[msg.sender].nextExec != 0;
        if (exists) {
            accountsParams[msg.sender].paused = true;
        } else {
            revert("Account does not exists yet");
        }
    }

    function setUnpause() external {
        bool exists = accountsParams[msg.sender].nextExec != 0;
        if (exists) {
            accountsParams[msg.sender].paused = false;
        } else {
            revert("Account does not exists yet");
        }
    }

    function getUserNeedExec() external view returns (address user) {
        for (uint256 i; i < accounts.length; i++) {
            AccountParams memory account = accountsParams[accounts[i]];
            bool execTime = isExecTime(accounts[i]);
            bool transactable = isTransactable(user);
            bool spendable = isSpendable(accounts[i], account.stableToken, account.amount);
            if (execTime && transactable && spendable) {
                user = accounts[i];
            }
        }
    }

    function isExecTime(address user) public view returns (bool) {
        return accountsParams[user].nextExec < block.timestamp;
    }

    function isTransactable(address user) private view returns (bool) {
        return treasury.balances(user) > maxSwapCost;
    }

    function isSpendable(
        address user,
        IERC20 stableToken,
        uint256 amount
    ) private view returns (bool) {
        uint256 allowance = stableToken.allowance(user, autoDca);
        return stableToken.balanceOf(user) > amount && allowance > amount;
    }

    function findPoolFee(IERC20 stableToken, IERC20 dcaIntoToken) private view returns (uint24) {
        uint24[3] memory fee = [uint24(100), uint24(500), uint24(3000)];
        for (uint256 i; i < fee.length; i++) {
            address poolAddress = uniswapFactory.getPool(address(stableToken), address(dcaIntoToken), fee[i]);
            if (poolAddress != address(0)) {
                return fee[i];
            }
        }

        string memory token0 = Strings.toHexString(uint256(uint160(address(stableToken))), 20);
        string memory token1 = Strings.toHexString(uint256(uint160(address(dcaIntoToken))), 20);
        string memory message = string(abi.encodePacked("No pool with tokens: ", token0, ", ", token1));

        revert(message);
    }
}
