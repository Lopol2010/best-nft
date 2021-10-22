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
    uint256 private _maxSupply;
    uint256 private _price;
    IERC20 private _currency;
    bool private _salesStarted;
    string private constant URI = "https://google.com/";

    constructor(IERC20 currencyToken, uint256 price, uint256 maxSupply) ERC721("Best", "BST") {
        _currency = currencyToken;
        _price = price;
        _maxSupply = maxSupply;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function safeMint(address to) private {
        _safeMint(to, _tokenIdCounter.current());
        _setTokenURI(_tokenIdCounter.current(), URI);
        _tokenIdCounter.increment();
    }

    function startSales() public onlyOwner {
        _salesStarted = true;
    }

    function totalSupply() public view  returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    // user approve on their side and then we can take their tokens and give new NFT in return
    function mint() external {
        require(_salesStarted, "Sales not started");
        require(_tokenIdCounter.current() < _maxSupply, "Max supply reached");
        _currency.transferFrom(msg.sender, address(this), _price);
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