const HDWalletProvider = require("@truffle/hdwallet-provider");
require('dotenv').config();

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
            provider: () => new HDWalletProvider(process.env.MNEMONIC, 
            "https://polygon-mumbai.infura.io/v3/09f56f531b7c4afb9fcdf5c711ecf700"),
            network_id: 80001,
            confirmations: 2,
            timeoutBlocks: 1000,
            skipDryRun: true,
            gas: 5000000,
            gasPrice: 20000000000,
        }
    },
    compilers: {
        solc: {
            version: "0.8.6"
        }
    },
    plugins: ['truffle-plugin-verify'],
    
    api_keys: {
        polygonscan: process.env.POLYGON_SCAN_API_KEY
      }
};