
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
        let interval = 2;
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
        await accountManager.setPause();
        let paused = (await accountManager.accountsParams(account)).paused;
        assert.isTrue(paused);
    });

    it('should unpause account', async () => {
        let account = await accountManager.accounts(0);
        assert.equal(account, accounts[0]);
        await accountManager.setPause();
        let paused = (await accountManager.accountsParams(account)).paused;
        assert.isTrue(paused);
        await accountManager.setUnpause();
        paused = (await accountManager.accountsParams(account)).paused;
        assert.isFalse(paused);
    });

    it('should return false for exec time', async () => {
        let account = await accountManager.accounts(0);
        let isTime = await accountManager.isExecTime(account);
        assert.isFalse(isTime);
    });

    it('should return true for exec time', async () => {
        let account = await accountManager.accounts(0);
        await sleep(3);
        // here should be any transaction that force block to be mined and change block.timestamp
        await accountManager.setUpAccount(50, 200, token0, token1, { from: accounts[1] });
        let isTime = await accountManager.isExecTime(account);
        assert.isTrue(isTime);
    });
});

async function sleep(sec) {
    await new Promise(resolve => setTimeout(resolve, sec * 1000));
}