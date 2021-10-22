//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Best.sol";

contract Royalty {

    address payable private bank;
    Best private nft;
    uint256 private bankPercent;
    bool private lockClaim;

    mapping(address => uint) private lastTimeClaimed;

    constructor(Best _nft, address payable _bank, uint256 _bankPercent) {
        bank = _bank;
        nft = _nft;
        bankPercent = _bankPercent;
    }

    receive() external payable {
        if(msg.value > 0 && bankPercent > 0) {
            (bool success, ) = bank.call{value: msg.value * bankPercent / 10000}("");
            require(success, "Re-route to bank failed");
        }
    }

    function setBank(address payable _bank) public {
        require(_bank != address(0));
        bank = _bank;
    }

    function setBankPercent(uint256 _percent) public {
        bankPercent = _percent;
    }

    function getTotalRoyalty() external view returns (uint256) {
        return address(this).balance;
    }

    function claim() public payable {
        require(!lockClaim, "Reentrant call!");
        lockClaim = true;
        require(address(this).balance > 0, "No royalty");
        require(nft.balanceOf(msg.sender) > 0, "You don't have NTFs");
        require(lastTimeClaimed[msg.sender] + 30 days <= block.timestamp, "Can't claim twice per month");

        uint256 userRoyalty = nft.balanceOf(msg.sender) * (payable(this).balance / nft.totalSupply());
        (bool success, ) = payable(msg.sender).call{value: userRoyalty}("");  
        require(success, "Transfer failed");
        lastTimeClaimed[msg.sender] = block.timestamp;
        lockClaim = false;
    }

}