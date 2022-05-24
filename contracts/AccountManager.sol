// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./AutoDca.sol";
import "./IOps.sol";

contract AccountManager {
    mapping(address => AccountParams) public accountsParams;
    address[] public accounts;

    AutoDca public immutable autoDca;
    IUniswapV3Factory public immutable uniswapFactory;
    IOps public immutable ops;

    struct AccountParams {
        uint256 interval;
        uint256 nextExec;
        uint256 swapBalance;
        uint256 amount;
        uint24 poolFee;
        IERC20 stableToken;
        IERC20 dcaIntoToken;
        bool paused;
    }

    modifier onlyAutoDca() {
        require(msg.sender == address(autoDca), "Caller is not the autoDca");
        _;
    }

    constructor(
        AutoDca _autoDca,
        IUniswapV3Factory _uniswapFactory,
        IOps _ops
    ) {
        autoDca = _autoDca;
        uniswapFactory = _uniswapFactory;
        ops = _ops;
        setUpTask(_ops, _autoDca);
    }

    function setUpTask(IOps _ops, AutoDca _autoDca) private {
        _ops.createTask(
            address(_autoDca),
            _autoDca.exec.selector,
            address(_autoDca),
            abi.encodeWithSelector(_autoDca.checker.selector)
        );
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
            0,
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
        deposit();
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
            bool spendable = isSpendable(accounts[i], account.stableToken, account.amount);
            if (execTime && spendable) {
                user = accounts[i];
            }
        }
    }

    function getSwapParams(address user)
        external
        view
        returns (
            uint256 swapBalance,
            uint24 poolFee,
            IERC20 stableToken,
            IERC20 dcaIntoToken,
            uint256 amount
        )
    {
        swapBalance = accountsParams[user].swapBalance;
        poolFee = accountsParams[user].poolFee;
        stableToken = accountsParams[user].stableToken;
        dcaIntoToken = accountsParams[user].dcaIntoToken;
        amount = accountsParams[user].amount;
    }

    function deposit() public payable {
        accountsParams[msg.sender].swapBalance += msg.value;
        payable(ops.taskTreasury()).transfer(msg.value);
    }

    function deductSwapBalance(address user, uint256 cost) external onlyAutoDca {
        accountsParams[user].swapBalance -= cost;
    }

    function isExecTime(address user) public view returns (bool) {
        return accountsParams[user].nextExec < block.timestamp;
    }

    function isSpendable(
        address user,
        IERC20 stableToken,
        uint256 amount
    ) private view returns (bool) {
        uint256 allowance = stableToken.allowance(user, address(autoDca));
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
