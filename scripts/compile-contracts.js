const fs = require("fs");
const path = require("path");
const solc = require("solc");

module.exports = function compileAll(mainContract) {
    let contract = mainContract + ".sol";
    resolved = path.resolve("contracts", contract);
    let source = fs.readFileSync(resolved, "utf8");

    const input = {
        language: "Solidity",
        sources: {
            [contract]: {
                content: source,
            },
        },
        settings: {
            outputSelection: {
                "*": {
                    "*": ["*"],
                },
            },
        },
    };

    function readContractsFrom(dir, relativePath) {
        const absolutePath = path.resolve(dir, relativePath);
        return fs.readFileSync(absolutePath, "utf8");
    }

    function findImports(relativePath) {
        let source;
        try {
            source = readContractsFrom("contracts", relativePath);
        } catch (error) {
            source = readContractsFrom("node_modules", relativePath);
        }
        return {contents: source};
    }

    let output = JSON.parse(solc.compile(JSON.stringify(input), {import: findImports}));

    let contracts = {};

    for (const value of Object.values(output.contracts)) {
        for (const [contractName, details] of Object.entries(value)) {
            let abi = details.abi;
            let bytecode = details.evm.bytecode.object;

            let contract = {};
            contract["abi"] = abi;
            contract["bytecode"] = bytecode;

            contracts[contractName] = contract;
        }
    }
    return contracts;
};
