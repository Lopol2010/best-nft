const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const { Signer } = require("@ethersproject/abstract-signer");

use(solidity);

describe("Royalty", function () {
  it("Defining Generals", async function () {
    // General
    provider = ethers.provider;
    accounts = await hre.ethers.getSigners();
  });
  it("Deploy TestCurrency", async function () {
    const ERC20 = await ethers.getContractFactory("TestCurrency");
    currency = await ERC20.deploy(ethers.utils.parseEther("1000.0"));
    await currency.deployed();

    const ERC20_2 = await ethers.getContractFactory("TestCurrency");
    currency2 = await ERC20_2.deploy(ethers.utils.parseEther("1000.0"));
    await currency2.deployed();
  })
  it("Deploy Best NFT", async function () {
    const Best = await ethers.getContractFactory("Best");
    best = await Best.deploy(
      currency.address, 
      ethers.utils.parseEther("1.0"),
      5
    );
    await best.deployed();
  });
  it("Deploy royalty", async function () {
    const Royalty = await ethers.getContractFactory("Royalty");

    bank = accounts[3];

    royalty = await Royalty.deploy(
      best.address, 
      bank.address,
      1000
    );
    await royalty.deployed();
  });
  it("Bank takes percent", async function () {
    await accounts[0].sendTransaction({
        from: accounts[0].address,
        to: royalty.address,
        value: ethers.utils.parseEther("1.0")
    });
    expect(await bank.getBalance()).to.equal(ethers.utils.parseEther("10000.1"))
    expect(await royalty.getTotalRoyalty()).to.equal(ethers.utils.parseEther("0.9"))
  })
  it("", async function () {
    await accounts[0].sendTransaction({
        from: accounts[0].address,
        to: royalty.address,
        value: ethers.utils.parseEther("1.0")
    });
    expect(await bank.getBalance()).to.equal(ethers.utils.parseEther("10000.1"))
  })
});