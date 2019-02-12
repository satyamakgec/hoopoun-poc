require('babel-register');
require('babel-polyfill');
const fs = require('fs');
const HDWalletProvider = require("truffle-hdwallet-provider");

module.exports = {
    networks: {
        development: {
            host: 'localhost',
            port: 8545,
            network_id: '*', // Match any network id
            gas: 7900000,
        },
        kovan: {
            provider: () => {
                const key = fs.readFileSync('./privKey').toString();
                let wallet = new HDWalletProvider(key, "https://kovan.infura.io/")
                return wallet
            },
            network_id: '42', // Match any network id
            gas: 7900000,
            gasPrice: 5000000000
        },
        coverage: {
            host: "localhost",
            network_id: "*",
            port: 8545,         // <-- If you change this, also set the port option in .solcover.js.
            gas: 0xfffffffff  , // <-- Use this high gas value
            gasPrice: 0x01      // <-- Use this low gas price
        }
    },
    compilers: {
        solc: {
        version: "native",  
        settings: {
            optimizer: {
            enabled: true, 
            runs: 200    
            }
        }
        }
    },
    mocha: {
        enableTimeouts: false
    }
};
