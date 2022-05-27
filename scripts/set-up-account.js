const ethers = require("ethers");
const compileAll = require("./compile-contracts");

require("dotenv").config();

async function main() {
    let wallet = ethers.Wallet.fromMnemonic(process.env.MNEMONIC);
    let output = compileAll("AutoDca");
    console.log(output);
}

main();