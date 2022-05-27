// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IAlpaNFT {
    function safeMint(address to) external returns (uint256);

}

contract BlindBoxNFT is Context, ERC721, ERC721Enumerable, Ownable, AccessControl, ERC721URIStorage, ReentrancyGuard {

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string public _baseURIPrefix = "https://plat.alpakingdom.net/blindbox/json/";
    IERC20 exchangingToken;
    IAlpaNFT alpaNFT;
    mapping(uint256 => uint8) public tokenLevel;
    mapping(uint256 => bool) public opened;
    mapping(uint8 => uint256) private prices;
    mapping(uint8 => uint256) private allLevelTotalSupply;
    address private proxyRegistryAddress;
    uint64 private _startTime;

    event MintTo(uint256 tokenId, uint8 level, address buyer);
    event OpenBlindBox(address indexed owner, uint256 indexed boxTokenId, uint256 indexed alpaTokenId);

    constructor(address alpaNFTAddress) ERC721("AlpaBlindBox", "ABB") {
        // init role config
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        alpaNFT = IAlpaNFT(alpaNFTAddress);
        _startTime = uint64(block.timestamp) + 30 * 24 * 60 * 60;
    }

    function getLevelInfo(uint8 _level) public view returns(uint256, uint256) {
        return(prices[_level], allLevelTotalSupply[_level]);
    }


    function setStartTime(uint64 startTime) public onlyOwner {
        _startTime = startTime;
    }

    function setExchangingToken(address _tokenAddress) public onlyOwner {
        exchangingToken = IERC20(_tokenAddress);
    }

    function getExchangeTokenAddress () public view returns (address) {
        return address(exchangingToken);
    }

    function setLevelPrice(uint8 _level, uint256 _price) public onlyOwner {
        prices[_level] = _price;
    }

    function setLevelTotalSupply(uint8 _level, uint256 _supply) public onlyOwner {
        allLevelTotalSupply[_level] = _supply;
    }


    modifier existLevel(uint8 _level) {
        require(prices[_level] != 0, "AlpaKingdom: not exist level");
        _;
    }

    function mintTo(uint8 _level, address _to) public existLevel(_level) returns(uint256){
        require(hasRole(MINTER_ROLE, _msgSender()), "AlpaKingdom: only minter!");
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        tokenLevel[tokenId] = _level;
        _safeMint(_to, tokenId);
        emit MintTo(tokenId, _level, _to);
        return tokenId;
    }

    function buy(uint8 _level, uint256 num) external payable nonReentrant existLevel(_level) {

        require(num > 0 && num < 1000, "AlpaKingdom: num error");
        require(uint64(block.timestamp) > _startTime, "AlpaKingdom: not started");
        // 判断是否卖完
        require(allLevelTotalSupply[_level] >= num, "AlpaKingdom: sale out");
        // 判断金额
        uint256 totalPrice = num.mul(prices[_level]);
        if (address(exchangingToken) == address(0)) {
            require(msg.value >= totalPrice, "AlpaKingdom: BNB amount not enough!");
        } else {
            require(exchangingToken.balanceOf(_msgSender()) >= totalPrice, "AlpaKingdom: Token amount not enough!");
        }
        allLevelTotalSupply[_level] = allLevelTotalSupply[_level] - num;

        if (address(exchangingToken) == address(0)) {
            payable (owner()).transfer(msg.value);
        } else {
            exchangingToken.transferFrom(_msgSender(), owner(), totalPrice);
        }
        for(uint256 i = 0; i < num; ++i) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            tokenLevel[tokenId] = _level;
            _safeMint(_msgSender(), tokenId);
            emit MintTo(tokenId, _level, _msgSender());
        }
    }

    function openBlindBox(uint256 _tokenId) public returns(uint256) {
        require(!opened[_tokenId], "AlpaKingdom: box is opened!");
        require(_msgSender() == ownerOf(_tokenId), "Not your box!");
        opened[_tokenId] = true;
        _burn(_tokenId);
        uint256 alpaTokenId = alpaNFT.safeMint(_msgSender());
        emit OpenBlindBox(_msgSender(), _tokenId, alpaTokenId);
        return alpaTokenId;
    }

    // common setup
    function _beforeTokenTransfer(address from, address to,  uint256 tokenId ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view  override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
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
