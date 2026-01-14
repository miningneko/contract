require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000  // Recommended: balanced deploy cost vs runtime efficiency
      }
    }
  },
  networks: {
    hardhat: {
      chainId: 31337
    },
  },
};
