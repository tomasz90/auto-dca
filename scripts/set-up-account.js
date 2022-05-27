const ethers = require("ethers");
const fs = require('fs');
const path = require("path");
const solc = require('solc');

require("dotenv").config();

async function main() {
    let wallet = ethers.Wallet.fromMnemonic(process.env.MNEMONIC);
    resolved = path.resolve('./contracts/AutoDca.sol');
    let source = fs.readFileSync(resolved, 'utf8').toString();

    const input = {
        language: 'Solidity',
        sources: {
          'AutoDca.sol': {
            content: source
          }
        },
        settings: {
          outputSelection: {
            '*': {
              '*': ['*']
            }
          }
        }
      };
      
      function findImports(relativePath) {
        //my imported sources are stored under the node_modules folder!
        const absolutePath1 = path.resolve('contracts', relativePath);
        const absolutePath2 = path.resolve('node_modules', relativePath);
        let source;
        try {
            source = fs.readFileSync(absolutePath1, 'utf8');
        } catch(error) {
            source = fs.readFileSync(absolutePath2, 'utf8');
        }     
        return { contents: source };
      }
      
      // New syntax (supported from 0.5.12, mandatory from 0.6.0)
      var output = JSON.parse(
        solc.compile(JSON.stringify(input), { import: findImports })
      );

    console.log(output);
}

main();