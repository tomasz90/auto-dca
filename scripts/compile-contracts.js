const fs = require('fs');
const path = require("path");
const solc = require('solc');

require("dotenv").config();

function compileAll(mainContract) {
    let contract = mainContract + '.sol'
    resolved = path.resolve('contracts', contract);
    let source = fs.readFileSync(resolved, 'utf8');

    const input = {
        language: 'Solidity',
        sources: {
          [contract]: {
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

      function readContractsFrom(dir) {
        const absolutePath = path.resolve(dir, relativePath);
        return fs.readFileSync(absolutePath, 'utf8');
      }
      
      function findImports(relativePath) {
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
      
      var output = JSON.parse(
        solc.compile(JSON.stringify(input), { import: findImports })
      );

    console.log(output);
}

compileAll("AutoDca");