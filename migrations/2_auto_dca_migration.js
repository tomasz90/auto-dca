const AutoDca = artifacts.require("AutoDca");

// Polygon Mumbai
const interval = "60";
const amount = "1000";
const stableToken = "0xe11A86849d99F524cAC3E7A0Ec1241828e332C62";
const dcaIntoToken = "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889";
const uniswapFactory = "0x1F98431c8aD98523631AE4a59f267346ea31F984";
const uniswapRouter = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";
const keeperRegistryAddress = "0x6179B349067af80D0c171f43E6d767E4A00775Cd";

module.exports = function (deployer) {
    deployer.deploy(AutoDca, interval, amount, stableToken, dcaIntoToken, uniswapFactory, uniswapRouter, keeperRegistryAddress);
};