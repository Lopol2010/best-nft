//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Best is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 private _totalSupply;
    uint256 private _price;
    IERC20 private _currency;
    bool private salesStarted;

    constructor(IERC20 currencyToken, uint256 price, uint256 maxSupply) ERC721("Best", "BST") {
        _currency = currencyToken;
        _price = price;
        _totalSupply = maxSupply;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://google.com/";
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function startSales() public onlyOwner {
        salesStarted = true;
    }

    // creates a new NFT and sends currency from buyer to owner of the contract
    function buy() public {
        require(salesStarted, "Sales didn't started");
        require(_tokenIdCounter.current() <= _totalSupply, "Max supply reached");
        require(_currency.balanceOf(msg.sender) >= _price, "Low balance");
    
        _currency.approve(address(this), _price);
        _currency.transferFrom(msg.sender, owner(), _price);
        safeMint(msg.sender);
    }

    //delegate token
    function delegate(address to, uint256 tokenId) public {
        approve(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}