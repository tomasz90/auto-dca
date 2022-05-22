const AutoDca = artifacts.require("AutoDca");

// Rinkeby
const uniswapFactory = "0x1F98431c8aD98523631AE4a59f267346ea31F984";
const executorAddress = "0xAE456ef27fEd5F52Fb650b114623c171258DB548";

module.exports = function (deployer) {
    deployer.deploy(AutoDca);
};