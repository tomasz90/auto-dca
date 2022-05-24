const ethers = require("ethers");
const Mock = artifacts.require("Mock");

module.exports = {
    assertRevert: async (promise) => {
        try {
            await promise;
            throw null;
        } catch (error) {
            assert(error, "Expected an error but did not get one");
            assert(
                error.message.startsWith("Returned error: VM Exception while processing transaction: revert"),
                "Expected a revert but got '" + error.message + "' instead"
            );
        }
    },

    sleep: async (sec) => {
        await new Promise((resolve) => setTimeout(resolve, sec * 1000));
        // here should be any transaction that force block to be mined and change block.timestamp
        let mock = await Mock.new();
        await mock.mockTransaction();
    },

    randomAddress: () => {
        return ethers.Wallet.createRandom().address;
    },
};
