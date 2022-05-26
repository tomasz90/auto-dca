const HDWalletProvider = require("@truffle/hdwallet-provider");
require("dotenv").config();

module.exports = {
    // See <http://truffleframework.com/docs/advanced/configuration>
    // to customize your Truffle configuration!
    networks: {
        development: {
            host: "127.0.0.1", // Localhost (default: none)
            port: 7548, // Standard Ethereum port (default: none)
            network_id: 10001, // Any network (default: none)
            gas: 600000000,
        },
        mumbai: {
            provider: () =>
                new HDWalletProvider(
                    process.env.MNEMONIC,
                    "https://polygon-mumbai.infura.io/v3/" + process.env.INFURA_API_KEY
                ),
            network_id: 80001,
            confirmations: 2,
            timeoutBlocks: 1000,
            skipDryRun: true,
            gas: 5000000,
            gasPrice: 20000000000,
        },
        rinkeby: {
            provider: () =>
                new HDWalletProvider(
                    process.env.MNEMONIC,
                    "https://rinkeby.infura.io/v3/" + process.env.INFURA_API_KEY
                ),
            network_id: 4,
            confirmations: 2,
            timeoutBlocks: 1000,
            skipDryRun: true,
            gas: 5000000,
            gasPrice: 10000000000,
        },
    },
    compilers: {
        solc: {
            version: "0.8.6",
        },
    },
    plugins: ["truffle-plugin-verify", "truffle-ganache-test", "truffle-plugin-stdjsonin"],
    api_keys: {
        polygonscan: process.env.POLYGON_SCAN_API_KEY,
        etherscan: process.env.ETHERSCAN_API_KEY,
    }
};
