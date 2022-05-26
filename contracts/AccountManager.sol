// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./AutoDca.sol";
import "./BalanceHolder.sol";
import "./IOps.sol";

contract AccountManager {
    mapping(address => AccountParams) public accountsParams;
    address[] public accounts;

    address public immutable autoDca;
    IUniswapV3Factory public immutable uniswapFactory;
    BalanceHolder public immutable balanceHolder;

    uint256 public constant maxSwapCost = 10**6;

    struct AccountParams {
        uint256 interval;
        uint256 nextExec;
        uint256 amount;
        uint24 poolFee;
        IERC20 sellToken;
        IERC20 buyToken;
        bool paused;
    }

    modifier onlyAutoDca() {
        require(msg.sender == autoDca, "Caller is not the autoDca");
        _;
    }

    constructor(
        address _autoDca,
        IUniswapV3Factory _uniswapFactory,
        IOps _ops
    ) {
        autoDca = _autoDca;
        uniswapFactory = _uniswapFactory;
        balanceHolder = new BalanceHolder(address(this), _autoDca, _ops);
    }

    function setUpAccount(
        uint256 interval,
        uint256 amount,
        IERC20 sellToken,
        IERC20 buyToken
    ) external {
        uint24 poolFee = findPoolFee(sellToken, buyToken);
        AccountParams memory params = AccountParams(
            interval,
            block.timestamp + interval,
            amount,
            poolFee,
            sellToken,
            buyToken,
            false
        );
        if (!isExisting()) {
            accounts.push(msg.sender);
        }
        accountsParams[msg.sender] = params;
    }

    function deposit() public payable {
        require(isExisting(), "Set up an account first");
        balanceHolder.deposit{value: msg.value}(msg.sender);
    }

    function deductSwapBalance(address user, uint256 cost) external onlyAutoDca {
        balanceHolder.deductSwapBalance(user, cost);
    }

    function setInterval(uint256 interval) external {
        if (isExisting()) {
            accountsParams[msg.sender].interval = interval;
        } else {
            revert("Account does not exists yet");
        }
    }

    function setAmount(uint256 amount) external {
        if (isExisting()) {
            accountsParams[msg.sender].amount = amount;
        } else {
            revert("Account does not exists yet");
        }
    }

    function setSellToken(IERC20 token) external {
        if (isExisting()) {
            accountsParams[msg.sender].sellToken = token;
        } else {
            revert("Account does not exists yet");
        }
    }

    function setBuyToken(IERC20 token) external {
        if (isExisting()) {
            accountsParams[msg.sender].buyToken = token;
        } else {
            revert("Account does not exists yet");
        }
    }

    function setNextExec(address user) external onlyAutoDca {
        accountsParams[user].nextExec += accountsParams[user].interval;
    }

    function setPause() external {
        if (isExisting()) {
            accountsParams[msg.sender].paused = true;
        } else {
            revert("Account does not exists yet");
        }
    }

    function setUnpause() external {
        if (isExisting()) {
            accountsParams[msg.sender].paused = false;
        } else {
            revert("Account does not exists yet");
        }
    }

    function getUserNeedExec() external view returns (address user) {
        for (uint256 i; i < accounts.length; i++) {
            AccountParams memory account = accountsParams[accounts[i]];
            bool execTime = isExecTime(accounts[i]);
            bool transactable = isTransactable(accounts[i]);
            bool spendable = isSpendable(accounts[i], account.sellToken, account.amount);
            if (execTime && transactable && spendable) {
                user = accounts[i];
            }
        }
    }

    function getToken(address user) external onlyAutoDca {
        AccountParams memory account = accountsParams[user];
        account.buyToken.transferFrom(user, autoDca, account.amount);
        account.buyToken.transfer(autoDca, account.amount);
    }

    function isExecTime(address user) public view returns (bool) {
        return accountsParams[user].nextExec < block.timestamp;
    }

    function isExisting() private view returns (bool) {
        return accountsParams[msg.sender].nextExec != 0;
    }

    function isTransactable(address user) private view returns (bool) {
        return balanceHolder.balances(user) > maxSwapCost * tx.gasprice;
    }

    function isSpendable(
        address user,
        IERC20 sellToken,
        uint256 amount
    ) private view returns (bool) {
        uint256 allowance = sellToken.allowance(user, autoDca);
        return sellToken.balanceOf(user) > amount && allowance > amount;
    }

    function findPoolFee(IERC20 sellToken, IERC20 buyToken) private view returns (uint24) {
        uint24[3] memory fee = [uint24(100), uint24(500), uint24(3000)];
        for (uint256 i; i < fee.length; i++) {
            address poolAddress = uniswapFactory.getPool(address(sellToken), address(buyToken), fee[i]);
            if (poolAddress != address(0)) {
                return fee[i];
            }
        }

        string memory token0 = Strings.toHexString(uint256(uint160(address(sellToken))), 20);
        string memory token1 = Strings.toHexString(uint256(uint160(address(buyToken))), 20);
        string memory message = string(abi.encodePacked("No pool with tokens: ", token0, ", ", token1));

        revert(message);
    }
}
