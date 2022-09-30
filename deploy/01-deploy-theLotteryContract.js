const ENTRANCE_FEE = ethers.utils.parseEther("0.1")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const args = [
        ENTRANCE_FEE,
        "300",
        "0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D",
        "0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15",
        "22455",
        "500000",
    ]

    const theLotteryContract = await deploy("theLotteryContract", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: 6,
    })
}
