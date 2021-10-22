//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Best is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 private maxSupply;
    uint256 private price;
    IERC20 private currency;
    bool private salesStarted;
    string private constant URI = "https://google.com/";

    mapping(address => uint256) private _balances;

    constructor(IERC20 _currencyToken, uint256 _price, uint256 _maxSupply) ERC721("Best", "BST") {
        currency = _currencyToken;
        price = _price;
        maxSupply = _maxSupply;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override (ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function getUserTotalNFT() external view returns (uint256) {
        return totalSupply();
    }

    function safeMint(address to) private {
        _safeMint(to, _tokenIdCounter.current());
        _setTokenURI(_tokenIdCounter.current(), URI);
        _tokenIdCounter.increment();
    }

    function startSales() public onlyOwner {
        salesStarted = true;
    }


    // user approve on their side and then we can take their tokens and give new NFT in return
    function mint() external {
        require(salesStarted, "Sales not started");
        require(totalSupply() < maxSupply, "Max supply reached");
        currency.transferFrom(msg.sender, address(this), price);
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