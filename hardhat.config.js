require("@nomiclabs/hardhat-waffle");
require('@nomiclabs/hardhat-ethers')

module.exports = {
  defaultNetwork: "goerliTestnet",
  networks: {
    hardhat: {
      accounts: { // 此字段可以配置为以下之一
        accountsBalance: "10000000000000000000000000000", //（10000 ETH）
        },
      // gasPrice: "auto",
      // gas: "auto", //限制。默认值：30000000 (3gwei)
      // blockGasLimit:3000000000000000,
      throwOnTransactionFailures: true,
      throwOnCallFailures: true,
      allowUnlimitedContractSize: true,
      blockGasLimit: 3000000000000000,
    },
    localhost: {
      url: `http://127.0.0.1:8545/`,
      accounts: [`0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`,
      `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d`,
      `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a`,
      `0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6`,
      '0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a',
      '0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba',
      '0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e',
      '0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356',
      '0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97',
      '0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6',
      '0xf214f2b2cd398c806f84e317254e0f0b801d0643303237d97a22a48e01628897',
      '0x701b615bbdfb9de65240bc28bd21bbc0d996645a3dd57e7b12bc2bdf6f192c82',
      '0xa267530f49f8280200edf313ee7af6b827f2a8bce2897751d06a843f644967b1',]
    },

  },
  // solidity: "0.7.5",
  
  solidity: {            // 因为有依赖所以需要多个合约的版本
    compilers: [
        {
            version: "0.7.5",
            settings: {
              // 用于设置超大合约
              optimizer: {
                enabled: true,
                runs: 200,
              },
            },
        },
        {
          version: "0.4.18"
        },
        {
            version: "0.8.0",
        },
        {
          version: "0.8.17",
          settings: {
            // 用于设置超大合约
            optimizer: {
              enabled: true,
              runs: 200,
            },
      
          },
      },{
        version: "0.8.19",

    },
        {
            version: "0.8.4",

        }
    ]
  },

};

