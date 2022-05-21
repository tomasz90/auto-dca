const AutoDca = artifacts.require("AutoDca");

// Rinkeby
const interval = "30";
const amount = "100";
const stableToken = "0x6A9865aDE2B6207dAAC49f8bCba9705dEB0B0e6D";
const dcaIntoToken = "0xc778417E063141139Fce010982780140Aa0cD5Ab";
const uniswapFactory = "0x1F98431c8aD98523631AE4a59f267346ea31F984";
const keeperRegistryAddress = "0x409CF388DaB66275dA3e44005D182c12EeAa12A0";

module.exports = function (deployer) {
    deployer.deploy(AutoDca, interval, amount, stableToken, dcaIntoToken, uniswapFactory, keeperRegistryAddress);
};