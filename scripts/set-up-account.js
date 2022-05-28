const ethers = require("ethers");
const compileAll = require("./compile-contracts");

require("dotenv").config();

main();

async function main() {
    // given for Rinkeby:
    const rpc = "https://rinkeby.infura.io/v3/" + process.env.INFURA_API_KEY;
    
    const uniswapRouter = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
    const uniswapFactory = "0x1F98431c8aD98523631AE4a59f267346ea31F984";
    const ops = "0x8c089073A9594a4FB03Fa99feee3effF0e2Bc58a";

    const approvalAmount = "10000000000000000000000000";
    const depositAmount = "10000000000000000"; // for paying transactions

    const interval = 60;
    const sellAmount = "1000000000000000000";
    const sellToken = "0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa";
    const buyToken = "0xc778417E063141139Fce010982780140Aa0cD5Ab";

    let contracts = compileAll("AutoDca");

    let provider = new ethers.providers.JsonRpcProvider(rpc);
    let wallet = ethers.Wallet.fromMnemonic(process.env.MNEMONIC).connect(provider);

    let autoDcaContract = await deployContracts(contracts, uniswapRouter, uniswapFactory, ops, wallet);
    await autoDcaContract.deployed();

    let managerAddress = await autoDcaContract.manager();
    let managerContract = new ethers.Contract(managerAddress, contracts.AccountManager.abi, provider).connect(wallet);

    let sellTokenContract = new ethers.Contract(sellToken, contracts.IERC20.abi, provider).connect(wallet);

    let tx = await sellTokenContract.approve(managerAddress, approvalAmount, {gasLimit: 500000});
    tx.wait(5);

    tx = await managerContract.setUpAccount(interval, sellAmount, sellToken, buyToken, {gasLimit: 500000});
    tx.wait(5);

    tx = await managerContract.deposit({value: depositAmount, gasLimit: 500000});
    tx.wait(5);
}

async function deployContracts(contracts, uniswapRouter, uniswapFactory, ops, wallet) {
    let {abi, bytecode} = contracts.AutoDca;

    let factory = new ethers.ContractFactory(abi, bytecode, wallet);

    let contract = await factory.deploy(uniswapRouter, uniswapFactory, ops);

    return contract;
}
