import { expect } from "chai";
import { ethers } from "hardhat";

describe("NftCollection", () => {
  async function deployNftCollection() {
    const [owner] = await ethers.getSigners();
    const NftCollectionFactory = await ethers.getContractFactory("NftCollection");
    const maxSupply = 1000n;

    const nft = await NftCollectionFactory.deploy(
      "MyNFT",
      "MNFT",
      maxSupply
    );
    await nft.waitForDeployment();

    return { nft, owner, maxSupply };
  }

  it("deploys with correct name, symbol, and maxSupply", async () => {
    const { nft, maxSupply } = await deployNftCollection();

    expect(await nft.name()).to.equal("MyNFT");
    expect(await nft.symbol()).to.equal("MNFT");
    expect(await nft.maxSupply()).to.equal(maxSupply);
    expect(await nft.totalSupply()).to.equal(0n);
  });

  it("reverts mint from non-owner", async () => {
    const { nft } = await deployNftCollection();
    const [, other] = await ethers.getSigners();

    await expect(
      nft.connect(other).mint(other.address, 0n)
    ).to.be.revertedWith("Only owner");
  });

  it("mints and updates totalSupply and owner", async () => {
    const { nft, owner } = await deployNftCollection();

    const tx = await nft.mint(owner.address, 0n);
    await tx.wait();

    expect(await nft.totalSupply()).to.equal(1n);
    expect(await nft.ownerOf(0n)).to.equal(owner.address);
    expect(await nft.balanceOf(owner.address)).to.equal(1n);
  });

  it("transfers a token correctly", async () => {
    const { nft, owner } = await deployNftCollection();
    const [, recipient] = await ethers.getSigners();

    await nft.mint(owner.address, 0n);

    await nft.transferFrom(owner.address, recipient.address, 0n);

    expect(await nft.ownerOf(0n)).to.equal(recipient.address);
    expect(await nft.balanceOf(owner.address)).to.equal(0n);
    expect(await nft.balanceOf(recipient.address)).to.equal(1n);
  });

  it("allows approved address to transfer token", async () => {
    const { nft, owner } = await deployNftCollection();
    const [, approved] = await ethers.getSigners();

    await nft.mint(owner.address, 0n);

    await nft.approve(approved.address, 0n);
    await nft.connect(approved).transferFrom(owner.address, approved.address, 0n);

    expect(await nft.ownerOf(0n)).to.equal(approved.address);
  });

  it("operator can transfer multiple tokens", async () => {
    const { nft, owner } = await deployNftCollection();
    const [, operator, to] = await ethers.getSigners();

    await nft.mint(owner.address, 0n);
    await nft.mint(owner.address, 1n);

    await nft.setApprovalForAll(operator.address, true);

    await nft.connect(operator).transferFrom(owner.address, to.address, 0n);
    await nft.connect(operator).transferFrom(owner.address, to.address, 1n);

    expect(await nft.balanceOf(to.address)).to.equal(2n);
  });

  it("reverts transfer of non-existent token", async () => {
    const { nft, owner } = await deployNftCollection();
    const [, to] = await ethers.getSigners();

    await expect(
      nft.transferFrom(owner.address, to.address, 999n)
    ).to.be.revertedWith("Operator query for nonexistent token");
  });

  it("reverts mint beyond max supply", async () => {
    const { nft, owner, maxSupply } = await deployNftCollection();

    for (let i = 0n; i < maxSupply; i++) {
      await nft.mint(owner.address, i);
    }

    await expect(
      nft.mint(owner.address, maxSupply)
    ).to.be.revertedWith("Max supply reached");
  });

  it("emits Transfer and Approval events correctly", async () => {
    const { nft, owner } = await deployNftCollection();
    const [, to, approved] = await ethers.getSigners();

    await expect(nft.mint(owner.address, 0n))
      .to.emit(nft, "Transfer")
      .withArgs(ethers.ZeroAddress, owner.address, 0n);

    await expect(nft.approve(approved.address, 0n))
      .to.emit(nft, "Approval")
      .withArgs(owner.address, approved.address, 0n);

    await expect(nft.setApprovalForAll(approved.address, true))
      .to.emit(nft, "ApprovalForAll")
      .withArgs(owner.address, approved.address, true);

    await expect(
      nft.transferFrom(owner.address, to.address, 0n)
    )
      .to.emit(nft, "Transfer")
      .withArgs(owner.address, to.address, 0n);
  });
});
