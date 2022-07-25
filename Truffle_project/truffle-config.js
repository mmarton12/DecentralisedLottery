const HDWalletProvider = require('@truffle/hdwallet-provider');
const fs = require('fs');

var mnemonic = 'develop emotion primary salute ripple tail cactus settle antenna ranch year extend';

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    rinkeby: {
      provider: () => new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/v3/659f1afb360d4216812ba13f477c4e97'),
      network_id: 4,
      gasPrice: 100000000000,
    },
  },
  compilers: {
    solc: {
      version: "0.8.13"
    }
  },
  db: {
    enabled: false,
    host: "127.0.0.1"
  }
};
