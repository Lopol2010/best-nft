//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Best is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 private maxSupply;
    uint256 private totalSupply;
    uint256 private price;
    IERC20 private currency;
    bool private salesStarted;
    string private constant URI = "https://google.com/";

    mapping(uint256 => uint256) private delegationTimestamp;
    mapping(address => mapping(uint256 => address)) private delegates;
    uint256 private totalDelegators;

    constructor(IERC20 _currencyToken, uint256 _price, uint256 _maxSupply) ERC721("Best", "BST") {
        currency = _currencyToken;
        price = _price;
        maxSupply = _maxSupply;
    }

    function getTotalDelegators() public view returns (uint256) {
        return totalDelegators;
    }

    function getDelegationTimestamp(uint256 _tokenId) public view returns (uint256) {
        return delegationTimestamp[_tokenId];
    }

    function getDelegatee(address _delegate, uint256 _tokenId) public view returns (address) {
        return delegates[_delegate][_tokenId];
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function delegate(address _delegatee, uint256 tokenId) public {
        require(msg.sender != address(0));
        require(msg.sender == ownerOf(tokenId));
        require(delegates[msg.sender][tokenId] != _delegatee);
        require(exists(tokenId));

        delegates[msg.sender][tokenId] = _delegatee;
        if(delegationTimestamp[tokenId] == 0)
            totalDelegators += 1;
        delegationTimestamp[tokenId] = block.timestamp;
    }

    function startSales() public onlyOwner {
        salesStarted = true;
    }

    // user approve on their side and then we can take their tokens and give new NFT in return
    function mint() external {
        require(salesStarted, "Sales not started");
        require(totalSupply < maxSupply, "Max supply reached");
        currency.transferFrom(msg.sender, address(this), price);

        _safeMint(msg.sender, _tokenIdCounter.current());
        _setTokenURI(_tokenIdCounter.current(), URI);
        _tokenIdCounter.increment();
        totalSupply += 1;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);

        totalSupply -= 1;
        totalDelegators -= 1;
        delegates[msg.sender][tokenId] = address(0);
        delegationTimestamp[tokenId] = 0;
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