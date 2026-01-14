const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("0xNEKO", function () {
    let Neko;
    let neko;
    let owner;
    let addr1;

    beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        Neko = await ethers.getContractFactory("OxNEKO");
        neko = await Neko.deploy();
    });

    it("Should have correct initial state", async function () {
        expect(await neko.name()).to.equal("0xNEKO");
        expect(await neko.symbol()).to.equal("0xNEKO");

        // Check chain binding
        const chainId = (await ethers.provider.getNetwork()).chainId;
        expect(await neko.DEPLOY_CHAIN_ID()).to.equal(chainId);

        // Verify no owner (removed Ownable)
        expect(neko.owner).to.be.undefined;
    });

    it("Should revert invalid solution length", async function () {
        const nonce = 12345;
        const fakeSolution = Array(10).fill(0); // Wrong length
        await expect(neko.mint(nonce, fakeSolution)).to.be.revertedWithCustomError(neko, "InvalidSolutionLength");
    });

    it("Should revert broken cycle", async function () {
        const nonce = 12345;
        const fakeSolution = Array(42).fill(0);

        // Should revert with custom error
        await expect(neko.mint(nonce, fakeSolution)).to.be.reverted;
    });

});
