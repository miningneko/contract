const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const Neko = await hre.ethers.getContractFactory("OxNEKO");
    const neko = await Neko.deploy();

    await neko.waitForDeployment(); // Ethers v6 syntax
    const address = await neko.getAddress();

    console.log("0xNEKO deployed to:", address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
