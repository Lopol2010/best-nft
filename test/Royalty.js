const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const { Signer } = require("@ethersproject/abstract-signer");

describe("Royalty", function () {
  const parse = ethers.utils.parseEther;
  const format = ethers.utils.formatEther;
  const CYCLE_DURATION = 60*60*24*31;
  it("Defining Generals", async function () {
    // General
    provider = ethers.provider;
    accounts = await hre.ethers.getSigners();
  });
  it("Deploy TestCurrency", async function () {
    const ERC20 = await ethers.getContractFactory("TestCurrency");
    currency = await ERC20.deploy(parse("1000.0"));
    await currency.deployed();

    const ERC20_2 = await ethers.getContractFactory("TestCurrency");
    currency2 = await ERC20_2.deploy(parse("1000.0"));
    await currency2.deployed();
  })
  it("Deploy Best NFT", async function () {
    const Best = await ethers.getContractFactory("Best");
    best = await Best.deploy(
      currency.address, 
      parse("1.0"),
      5
    );
    await best.deployed();
  });
  it("Deploy royalty", async function () {
    const Royalty = await ethers.getContractFactory("Royalty");

    bank = accounts[3];

    royalty = await Royalty.deploy(
      best.address, 
      parse("1"),
      bank.address,
      1000
    );
    await royalty.deployed();
  });
  it("Bank takes percent", async function () {
    await accounts[0].sendTransaction({
        from: accounts[0].address,
        to: royalty.address,
        value: parse("2.0")
    });
    expect(await bank.getBalance()).to.be.gt(parse("10000.19"))
    expect(await provider.getBalance(royalty.address)).to.equal(parse("1.8"))
  })
  it("Mint some NFTs", async function () {
    await currency.transfer(accounts[2].address, parse("100.0"));
    await best.startSales();
    await currency.approve(best.address, parse("10.0"));
    await best.mint();
    await currency.connect(accounts[2]).approve(best.address, parse("10.0"));
    await best.connect(accounts[2]).mint();
  })
  it("Royalty can be claimed only if NFT was delegated a month ago and before royalty deposited", async function () { 
    await accounts[0].sendTransaction({
      from: accounts[0].address,
      to: royalty.address,
      value: parse("2.0")
    });
    await expect(royalty.claim([0])).to.be.revertedWith("Too soon");
    await provider.send("evm_increaseTime", [CYCLE_DURATION]); // here first cycle is ended, and new one starts
    await provider.send("evm_mine");
    await expect(royalty.claim([0])).to.be.revertedWith("NFT should be delegated");
    await best.delegate(accounts[0].address, 0); // delegate after first cycle start, so cant claim reward for that cycle
    await expect(royalty.claim([0])).to.be.revertedWith("Nothing to claim"); 
    await expect(accounts[1].sendTransaction({
        from: accounts[1].address,
        to: royalty.address,
        value: parse("2.0")
    })).to.be.not.reverted;
    await provider.send("evm_increaseTime", [CYCLE_DURATION]);
    await provider.send("evm_mine");
    await expect(royalty.claim([0])).to.be.revertedWith("Nothing to claim") // delegated after first cycle started, and current cycle is still not ended
    await expect(accounts[1].sendTransaction({
        from: accounts[1].address,
        to: royalty.address,
        value: parse("2.0")
    })).to.be.not.reverted;
    await provider.send("evm_increaseTime", [CYCLE_DURATION]);
    await provider.send("evm_mine");
    expect(await accounts[0].getBalance()).to.be.lt(parse("9997.0")); 
    await expect(royalty.claim([0])).to.be.not.reverted; // delegated before second cycle started and claim when third cycle started, (so claimed for second cycle)
    expect(await accounts[0].getBalance()).to.be.gt(parse("9997.0")); 
  })
  // it("Can't claim claimed", async function () {
  //   await expect(royalty.claim([0])).to.be.revertedWith("Nothing to claim");
  // })
  // it("Multiple claimers", async function () {
  //   await currency.transfer(accounts[5].address, parse("100.0"));
  //   await currency.transfer(accounts[4].address, parse("100.0"));
  //   await accounts[7].sendTransaction({
  //       from: accounts[7].address,
  //       to: royalty.address,
  //       value: parse("100.0")
  //   });
  //   await currency.connect(accounts[4]).approve(best.address, parse("10.0"));
  //   await best.connect(accounts[4]).mint();
  //   await currency.connect(accounts[5]).approve(best.address, parse("10.0"));
  //   await best.connect(accounts[5]).mint();

  //   await expect(royalty.claim([0])).to.be.reverted;
    // await expect(royalty.connect(accounts[5]).claim([3])).to.be.revertedWith("NFT should be delegated");

    // await best.connect(accounts[4]).delegate(best.address, 2); //dont care about delegatee address
    // await best.connect(accounts[5]).delegate(best.address, 3);

    // await provider.send("evm_increaseTime", [60*60*24*29]);
    // await provider.send("evm_mine");
    // await expect(accounts[1].sendTransaction({
    //     from: accounts[1].address,
    //     to: royalty.address,
    //     value: parse("1.0")
    // })).to.be.not.reverted;

    // await provider.send("evm_increaseTime", [60*60*24*29]);
    // await provider.send("evm_mine");
    // await royalty.claim([0]);
    // await royalty.connect(accounts[4]).claim([2]);
    // await royalty.connect(accounts[5]).claim([3]);

    // // 1.0 eth should be divided by 3 users, which is 0.333333 but bank takes some, so compare with 0.2
    // expect(await accounts[4].getBalance()).to.be.gt(parse("10000.2"))
    // expect(await accounts[5].getBalance()).to.be.gt(parse("10000.2"))
    // expect(await accounts[0].getBalance()).to.be.gt(parse("10090"))

  // })
});