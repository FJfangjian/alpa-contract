// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AlpaNFT is
ERC721,
ERC721Enumerable,
Ownable,
AccessControl,
ERC721URIStorage
{
    using SafeMath for uint256;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping(uint256 => uint256[2]) public _parents;
    mapping(uint256 => uint256) public _breedTimes;
    mapping(uint256 => uint64) public _birthdays;
    string public _baseURIPrefix = "https://plat.alpakingdom.net/alpa/json/";
    address private proxyRegistryAddress;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("AlpaNFT", "Alpa") {
        // init role config
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    // start from tokenId = 1; all minted tokens(include airdrops)' parents are uint256(0)
    function safeMint(address to) public virtual returns(uint256) {
        require(hasRole(MINTER_ROLE, msg.sender), "AlpaKingdom: only minter!");
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _birthdays[tokenId] = uint64(block.timestamp);
        _safeMint(to, tokenId);
        return tokenId;
    }

    function breedMint(address to, uint256[2] memory parentsId) public virtual returns(uint256) {
        require(hasRole(MINTER_ROLE, msg.sender), "AlpaKingdom: only minter!");
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _setParents(tokenId, parentsId);
        for (uint256 i = 0; i < parentsId.length; i++) {
            _breedTimes[parentsId[i]] = _breedTimes[parentsId[i]].add(1);
        }
        _safeMint(to, tokenId);
        return tokenId;
    }

    function _setParents(uint256 childId, uint256[2] memory parentsId) internal {
        require(!_exists(childId), "childId exists");
        _parents[childId] = parentsId;
    }

    function checkParents(uint256 tokenId) public view returns(uint256[2] memory) {
        require(_exists(tokenId), "AlpaKingdom: query for nonexistance tokenId");
        return _parents[tokenId];
    }

    function checkBreedTimes(uint256 tokenId) public view returns(uint256) {
        return _breedTimes[tokenId];
    }

    function checkBirthday(uint256 tokenId) public view returns(uint256) {
        return _birthdays[tokenId];
    }

    function _beforeTokenTransfer(address from, address to,  uint256 tokenId ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view  override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURIPrefix = baseURI;
    }

    function _baseURI() internal view override(ERC721) returns(string memory) {
        return _baseURIPrefix;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {

        return ERC721URIStorage.tokenURI(tokenId);
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) public onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function isApprovedForAll(address owner, address operator) override public view returns (bool)
    {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (operator == proxyRegistryAddress) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }


}
