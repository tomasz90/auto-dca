const BalanceHolder = artifacts.require("BalanceHolder");

const OpsMock = artifacts.require("OpsMock");
const TaskTreasuryMock = artifacts.require("TaskTreasuryMock");

const {assertRevert, randomAddress} = require("./helpers");

contract("BalanceHolder", (accounts) => {
    let manager = accounts[0];
    let balanceHolder;

    beforeEach(async () => {
        let ops = await OpsMock.new();
        let taskTreasury = await TaskTreasuryMock.new();
        await ops.setTaskTreasury(taskTreasury.address);
        balanceHolder = await BalanceHolder.new(randomAddress(), ops.address);
    });

    it("should create user balance", async () => {
        // given
        let user = accounts[1];
        let gwei = 1000000000;

        // when
        await balanceHolder.deposit(user, {value: gwei, from: manager});

        // then
        let balance = await balanceHolder.balances.call(user);
        assert.equal(balance, gwei);
    });

    it("should create user balance", async () => {
        // given
        let user = accounts[1];
        let gwei = 1000000000;
        await balanceHolder.deposit(user, {value: gwei, from: manager});

        // when
        await balanceHolder.deposit(user, {value: gwei, from: manager});

        // then
        let balance = await balanceHolder.balances.call(user);
        assert.equal(balance, 2 * gwei);
    });

    it("Not manager should not be able to deduct balance", async () => {
        // given
        let notManager = accounts[1];
        let gwei = 1000000000;

        // when
        let deduct = balanceHolder.deductSwapBalance(notManager, gwei, {from: notManager});

        // then
        assertRevert(deduct);
    });
});
