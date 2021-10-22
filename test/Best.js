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
  })
  it("Can't mint when sales not started", async function () {
    await currency.approve(best.address, ethers.utils.parseEther("2.0"));
    // here await before 'expect' because 'revertedWith' is async
    await expect(best.connect(accounts[0]).mint()).to.be.revertedWith('Sales not started');
  });
  it("Token URI should be predefined", async function () {
    await best.startSales();
    await currency.approve(best.address, ethers.utils.parseEther("2.0"))
    await best.mint();
    expect(await best.balanceOf(accounts[0].address)).to.equal(1);
    expect(await best.tokenURI(0)).to.equal("https://google.com/");
  });
  it("Can mint when sales started", async function () {
    await currency.transfer(accounts[1].address, ethers.utils.parseEther("2.0"));
    // currency.transfer(best.address, ethers.utils.parseEther("2.0"));
    await currency.connect(accounts[1]).approve(best.address, ethers.utils.parseEther("2.0"));
    expect(await currency.balanceOf(accounts[1].address)).to.equal(ethers.utils.parseEther("2.0"));
    await best.connect(accounts[1]).mint();
    expect(await best.balanceOf(accounts[1].address)).to.equal(1);
    expect(await currency.balanceOf(accounts[1].address)).to.equal(ethers.utils.parseEther("1.0"));
    // await expect(await best.balanceOf(accounts[1].address)).to.equal(1);
  });
  it("Owners can delegate their NFTs", async function () {
    expect(await best.getApproved(0)).to.equal(ethers.constants.AddressZero);
    await best.delegate(accounts[1].address, "0");
    expect(await best.balanceOf(accounts[1].address)).to.equal(1);
    expect(await best.balanceOf(accounts[0].address)).to.equal(1);
    expect(await best.getApproved(0)).to.equal(accounts[1].address);
    // await expect(await best.balanceOf(accounts[1].address)).to.equal(1);
  });
  it("Can't pay with other ERC20 tokens", async function () {
    currency2.transfer(accounts[3].address, ethers.utils.parseEther("2.0"))
    expect(await currency.balanceOf(accounts[3].address)).to.equal(ethers.constants.AddressZero);
    expect(await currency2.balanceOf(accounts[3].address)).to.equal(ethers.utils.parseEther("2.0"));
    currency2.connect(accounts[3]).approve(best.address, ethers.utils.parseEther("2.0"));
    await expect(best.connect(accounts[3]).mint()).to.be.revertedWith('ERC20: transfer amount exceeds balance');
  });
  
  it("Test max supply limit", async function () {
    currency.approve(best.address, ethers.utils.parseEther("500.0"))
    await best.mint();
    await best.mint(); // 4th
    await best.mint(); // 5th
    await expect(best.mint()).to.be.revertedWith("Max supply reached");
  });
});
