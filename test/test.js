
const AccountManager = artifacts.require("AccountManager");
const IUniswapV3FactoryMock = artifacts.require("IUniswapV3FactoryMock");

contract("AccountManager", (accounts) => {
    let accountManager;
    let uniswapV3Factory;

    let autoDca = "0x0000000000000000000000000000000000000002"
    let token0 = "0x0000000000000000000000000000000000000003"
    let token1 = "0x0000000000000000000000000000000000000004"

    beforeEach(async () => {
        uniswapV3Factory = await IUniswapV3FactoryMock.new();
        accountManager = await AccountManager.new(uniswapV3Factory.address, autoDca);
        let interval = 120;
        let amount = 200;
        await accountManager.setUpAccount(interval, amount, token0, token1);
    });

    it('should set up an account', async () => {
        let interval = 60;
        let amount = 100;
        await accountManager.setUpAccount(interval, amount, token0, token1, { from: accounts[1] });
        let account = await accountManager.accounts(1);
        assert.equal(account, accounts[1]);
        let params = await accountManager.accountsParams(account);
        assert.equal(params.interval, interval);
        assert.equal(params.amount, amount);
    });

    it('should pause account', async () => {
        let account = await accountManager.accounts(0);
        assert.equal(account, accounts[0]);
        await accountManager.pause();
        let paused = (await accountManager.accountsParams(account)).paused;
        assert.equal(paused, true);
    });

    it('should unpause account', async () => {
        let account = await accountManager.accounts(0);
        assert.equal(account, accounts[0]);
        await accountManager.pause();
        let paused = (await accountManager.accountsParams(account)).paused;
        assert.equal(paused, true);
        await accountManager.unpause();
        paused = (await accountManager.accountsParams(account)).paused;
        assert.equal(paused, false);
    });
});