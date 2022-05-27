const ethers = require("ethers");
const compileAll = require("./compile-contracts");

require("dotenv").config();

async function main() {

    let contracts = compileAll("AutoDca");
  
    let provider = ethers.getDefaultProvider('rinkeby');
    let wallet = ethers.Wallet.fromMnemonic(process.env.MNEMONIC).connect(provider);

    // deployContracts(abi, bytcode, wallet);

    let autoDcaContract = new ethers.Contract("0x88955862200ac3c2d630f3c5b31072e06d75f2c4", contracts.AutoDca.abi, provider);

    let managerAddress = await autoDcaContract.manager();

    let managerContract = new ethers.Contract(managerAddress, contracts.AccountManager.abi, provider).connect(wallet);

    await managerContract.setPause();

}

async function deployContracts(contracts, wallet) {

    let { abi, bytecode } = contracts.AutoDca;

    let factory = new ethers.ContractFactory(abi, bytecode, wallet);

    // Rinkeby
    const uniswapRouter = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
    const uniswapFactory = "0x1F98431c8aD98523631AE4a59f267346ea31F984";
    const ops = "0x8c089073A9594a4FB03Fa99feee3effF0e2Bc58a";

    let contract = await factory.deploy(uniswapRouter, uniswapFactory, ops);

    return contract.address;
}

main();


