const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");

use(solidity);

describe("Best", function () {
  it("Defining Generals", async function () {
    // General
    provider = ethers.provider;
    accounts = await hre.ethers.getSigners();
  });
  it("Deploy TestCurrency", async function () {
    const ERC20 = await ethers.getContractFactory("TestCurrency");
    currency = await ERC20.deploy(ethers.utils.parseEther("1000.0"));
    await currency.deployed();
  })
  it("Deploy Best NFT", async function () {
    const Best = await ethers.getContractFactory("Best");
    best = await Best.deploy(
      currency.address, 
      ethers.utils.parseEther("1.0"),
      100
    );
    await best.deployed();
  })
  it("Token URI should be predefined", async function () {
    best.safeMint(accounts[0].address);
    expect(await best.tokenURI(0)).to.equal("https://google.com/");
  });
  it("Should revert on mint when sales not started", async function () {
    await expect(best.mint()).to.be.revertedWith('Sales not started');
  });
  it("Should revert if not enough payed for NFT", async function () {
    best.startSales();
    await expect(best.connect(accounts[1]).mint()).to.be.revertedWith('ERC20: transfer amount exceeds balance');
  });
  it("Mint NFT", async function () {
    currency.transfer(accounts[0].address, ethers.utils.parseEther("2.0"))
    await expect(best.connect(accounts[1]).mint()).to.be.revertedWith('ERC20: transfer amount exceeds balance');
  });
});
