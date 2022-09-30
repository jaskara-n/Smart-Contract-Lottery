require("hardhat-deploy")
require("dotenv").config()
require("@nomiclabs/hardhat-waffle")

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    networks: {
        Goerli: {
            url: process.env.GOERLI_RPC_URL,
            accounts: [process.env.PRIVATE_KEY],
            chainId: 5,
            saveDeployments: true,
        },
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
    },
    solidity: "0.8.8",
}
