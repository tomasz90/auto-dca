const Treasury = artifacts.require("Treasury");

const OpsMock = artifacts.require("OpsMock");

const {assertRevert, randomAddress} = require("./helpers");

contract(Treasury, (accounts) => {

    let manager;
    let treasury;

    beforeEach(async () => {
        manager = accounts[1];
        let ops = await OpsMock.new();
        treasury = await Treasury.new(manager, randomAddress(), ops.address);
    });

    it("should create user balance", async () => {
        // given
        let user = accounts[0];
        let gwei = 1000000000;

        // when
        await treasury.deposit(user, {value: gwei, from: manager});

        // then
        let balance = await treasury.balances.call(user);
        assert.equal(balance, gwei);
    })

    it("should create user balance", async () => {
        // given
        let user = accounts[0];
        let gwei = 1000000000;
        await treasury.deposit(user, {value: gwei, from: manager});

        // when
        await treasury.deposit(user, {value: gwei, from: manager});

        // then
        let balance = await treasury.balances.call(user);
        assert.equal(balance, 2 * gwei);
    })

    it("Not manager should not be able to deduct balance", async () => {
        // given
        let notManager = accounts[0];
        let gwei = 1000000000;

        // when
        let deduct = treasury.deductSwapBalance(notManager, gwei, {from: notManager});

        // then
        assertRevert(deduct);
    })
});
