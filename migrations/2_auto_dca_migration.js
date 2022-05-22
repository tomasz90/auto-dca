const AutoDca = artifacts.require("AutoDca");

// Rinkeby
const uniswapFactory = "0x1F98431c8aD98523631AE4a59f267346ea31F984";
const uniswapRouter = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
const ops = "0x8c089073A9594a4FB03Fa99feee3effF0e2Bc58a";

module.exports = function (deployer) {
    deployer.deploy(AutoDca, uniswapFactory, uniswapRouter, ops);
};