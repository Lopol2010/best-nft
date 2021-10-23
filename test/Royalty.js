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
    expect(await provider.getBalance(royalty.address)).to.equal(ethers.utils.parseEther("0.9"))
  })
  it("Mint some NFTs", async function () {
    await currency.transfer(accounts[2].address, ethers.utils.parseEther("100.0"));
    await best.startSales();
    await currency.approve(best.address, ethers.utils.parseEther("10.0"));
    await best.mint();
    await currency.connect(accounts[2]).approve(best.address, ethers.utils.parseEther("10.0"));
    await best.connect(accounts[2]).mint();
  })
  it("Royalty can be claimed only if NFT was delegated a month ago and before royalty deposited", async function () { 
    await expect(royalty.claim([0])).to.be.revertedWith("Not delegated");
    await best.delegate(accounts[0].address, 0);
    await expect(royalty.claim([0])).to.be.revertedWith("Nothing to claim");
    await expect(accounts[1].sendTransaction({
        from: accounts[1].address,
        to: royalty.address,
        value: ethers.utils.parseEther("1.0")
    })).to.be.revertedWith("Cant deposit twice a month");
    await provider.send("evm_increaseTime", [60*60*24*29]);
    await provider.send("evm_mine");
    await expect(accounts[1].sendTransaction({
        from: accounts[1].address,
        to: royalty.address,
        value: ethers.utils.parseEther("1.0")
    })).to.be.not.reverted;
    await provider.send("evm_increaseTime", [60*60*24*29]);
    await provider.send("evm_mine");
    expect(await accounts[0].getBalance()).to.be.lt(ethers.utils.parseEther("9999.0")); 
    await expect(royalty.claim([0])).to.be.not.reverted;
    expect(await accounts[0].getBalance()).to.be.gt(ethers.utils.parseEther("9999.0")); 
  })
  it("Can't claim twice per month", async function () {
    await expect(royalty.claim([0])).to.be.revertedWith("Nothing to claim");
  })
  it("Multiple claimers", async function () {
    await currency.transfer(accounts[5].address, ethers.utils.parseEther("100.0"));
    await currency.transfer(accounts[4].address, ethers.utils.parseEther("100.0"));
    await accounts[7].sendTransaction({
        from: accounts[7].address,
        to: royalty.address,
        value: ethers.utils.parseEther("100.0")
    });
    await currency.connect(accounts[4]).approve(best.address, ethers.utils.parseEther("10.0"));
    await best.connect(accounts[4]).mint();
    await currency.connect(accounts[5]).approve(best.address, ethers.utils.parseEther("10.0"));
    await best.connect(accounts[5]).mint();

    await royalty.claim([0]);
    await expect(royalty.connect(accounts[5]).claim([3])).to.be.revertedWith("Not delegated");

    await best.connect(accounts[4]).delegate(best.address, 2); //dont care about delegatee address
    await best.connect(accounts[5]).delegate(best.address, 3);

    await provider.send("evm_increaseTime", [60*60*24*29]);
    await provider.send("evm_mine");
    await expect(accounts[1].sendTransaction({
        from: accounts[1].address,
        to: royalty.address,
        value: ethers.utils.parseEther("1.0")
    })).to.be.not.reverted;

    await provider.send("evm_increaseTime", [60*60*24*29]);
    await provider.send("evm_mine");
    await royalty.claim([0]);
    await royalty.connect(accounts[4]).claim([2]);
    await royalty.connect(accounts[5]).claim([3]);

    // 1.0 eth should be divided by 3 users, which is 0.333333 but bank takes some, so compare with 0.2
    expect(await accounts[4].getBalance()).to.be.gt(ethers.utils.parseEther("10000.2"))
    expect(await accounts[5].getBalance()).to.be.gt(ethers.utils.parseEther("10000.2"))
    expect(await accounts[0].getBalance()).to.be.gt(ethers.utils.parseEther("10090"))

  })
});