const fs = require('fs');
const path = require("path");
const solc = require('solc');

module.exports = function compileAll(mainContract) {
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

      function readContractsFrom(dir, relativePath) {
        const absolutePath = path.resolve(dir, relativePath);
        return fs.readFileSync(absolutePath, 'utf8');
      }
      
      function findImports(relativePath) {
        let source;
        try {
            source = readContractsFrom('contracts', relativePath);
        } catch(error) {
            source = readContractsFrom('node_modules', relativePath);
        }     
        return { contents: source };
      }
      
      var output = JSON.parse(
        solc.compile(JSON.stringify(input), { import: findImports })
      );
      return output;
}