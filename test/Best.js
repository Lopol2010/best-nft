const { expect } = require("chai");
const { ethers } = require("hardhat");

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
  it("Should not be able to mint when sales not started", async function () {
    expect(await best.mint()).to.be.revertedWith("Sales didn't started");
  });
});
