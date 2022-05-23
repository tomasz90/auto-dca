const AccountManager = artifacts.require("AccountManager");
const IUniswapV3FactoryMock = artifacts.require("IUniswapV3FactoryMock");
const IERC20Mock = artifacts.require("IERC20Mock");
const Mock = artifacts.require("Mock");

contract("AccountManager", (accounts) => {
    let accountManager;
    let uniswapV3Factory;

    let autoDca = "0x0000000000000000000000000000000000000002"

    beforeEach(async () => {
        uniswapV3Factory = await IUniswapV3FactoryMock.new();
        accountManager = await AccountManager.new(uniswapV3Factory.address, autoDca);
        token0 = await IERC20Mock.new(); 
        token1 = await IERC20Mock.new();

        // given
        let interval = 2;
        let amount = 100;
        await accountManager.setUpAccount(interval, amount, token0.address, token1.address);
    });

    it('should set up an account', async () => {
        // given
        let interval = 60;
        let amount = 100;

        // when
        await accountManager.setUpAccount(interval, amount, token0.address, token1.address, { from: accounts[1] });

        // then
        let account = await accountManager.accounts(1);
        assert.equal(account, accounts[1]);
        let params = await accountManager.accountsParams(account);
        assert.equal(params.interval, interval);
        assert.equal(params.amount, amount);
    });

    it('should pause and unpause account', async () => {
        // given
        let account = await accountManager.accounts(0);
        assert.equal(account, accounts[0]);

        // when
        await accountManager.setPause();
        let paused = (await accountManager.accountsParams(account)).paused;
        
        // then
        assert.isTrue(paused);

        // when
        await accountManager.setUnpause();

        // then
        paused = (await accountManager.accountsParams(account)).paused;
        assert.isFalse(paused);
    });

    it('should return false for exec time', async () => {
        // given
        let account = await accountManager.accounts(0);

        // when
        let isTime = await accountManager.isExecTime(account);

        // then
        assert.isFalse(isTime);
    });

    it('should return true for exec time', async () => {
        // given, wait for exect time
        let account = await accountManager.accounts(0);
        await sleep(3);

        // when
        let isTime = await accountManager.isExecTime(account);

        // then
        assert.isTrue(isTime);
    });

    it('should return user which need exec', async () => {
        // given, check user with positive allowance, positive balance and passed exec time
        await sleep(3);

        // when
        let account = await accountManager.getUserNeedExec();

        // then
        assert.equal(account, accounts[0]);
    })
});

async function sleep(sec) {
    await new Promise(resolve => setTimeout(resolve, sec * 1000));
    // here should be any transaction that force block to be mined and change block.timestamp
    let mock = await Mock.new();
    await mock.mockTransaction();
}