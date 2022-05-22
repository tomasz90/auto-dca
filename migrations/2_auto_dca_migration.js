const AutoDca = artifacts.require("AutoDca");

// Rinkeby
const uniswapFactory = "0x1F98431c8aD98523631AE4a59f267346ea31F984";
const uniswapRouter = "0xE592427A0AEce92De3Edee1F18E0157C05861564";

module.exports = function (deployer) {
    deployer.deploy(AutoDca, uniswapFactory, uniswapRouter);
};