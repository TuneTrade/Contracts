// Allows us to use ES6 in our migrations and tests.
require('babel-register')
var HDWalletProvider = require('truffle-hdwallet-provider')
var mnemonic = 'repeat entry search'
module.exports = {
  solc: {
    optimizer: {
      enabled: true,
      runs: 100
    }
  },
  networks: {
    development: {
      host: '127.0.0.1',
      port: 7545,
      network_id: '5777', // Match any network id
      gas: 914366353,
      gasPrice: 1
    },
    rinkeby: {
      host: 'https://rinkeby.infura.io/FiZkooYHIsk3keP6qjT7',
      // port: 8545,
      network_id: '*', // Match any network id
      gas: 914366353,
      from: '0xfb8e385876ca18d15308e8e0e2b6d026ddf6995a'
    },
    ropsten: {
      gas: 8000000,
      provider: function () {
        return new HDWalletProvider(
          'measure hair host addict predict service happy tree female rib floor demise',
          'https://ropsten.infura.io/FiZkooYHIsk3keP6qjT7'
        )
      },
      network_id: 3,
      confirmations: 2, // # of confs to wait between deployments. (default: 0)
      // timeoutBlocks: 200, // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true
    }
  }
}
