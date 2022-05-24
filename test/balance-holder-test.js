const BalanceHolder = artifacts.require("BalanceHolder");

const OpsMock = artifacts.require("OpsMock");

const {assertRevert, randomAddress} = require("./helpers");

contract(BalanceHolder, (accounts) => {

    let manager;
    let balanceHolder;

    beforeEach(async () => {
        manager = accounts[1];
        let ops = await OpsMock.new();
        balanceHolder = await BalanceHolder.new(manager, randomAddress(), ops.address);
    });

    it("should create user balance", async () => {
        // given
        let user = accounts[0];
        let gwei = 1000000000;

        // when
        await balanceHolder.deposit(user, {value: gwei, from: manager});

        // then
        let balance = await balanceHolder.balances.call(user);
        assert.equal(balance, gwei);
    })

    it("should create user balance", async () => {
        // given
        let user = accounts[0];
        let gwei = 1000000000;
        await balanceHolder.deposit(user, {value: gwei, from: manager});

        // when
        await balanceHolder.deposit(user, {value: gwei, from: manager});

        // then
        let balance = await balanceHolder.balances.call(user);
        assert.equal(balance, 2 * gwei);
    })

    it("Not manager should not be able to deduct balance", async () => {
        // given
        let notManager = accounts[0];
        let gwei = 1000000000;

        // when
        let deduct = balanceHolder.deductSwapBalance(notManager, gwei, {from: notManager});

        // then
        assertRevert(deduct);
    })
});
