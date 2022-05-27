// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IAlpaNFT {
    function breedMint(address to, uint256[2] memory parentsId) external returns (uint256);
    function checkBirthday(uint256 tokenId) external returns (uint64);
    function checkBreedTimes(uint256 tokenId) external returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IAlpa20 {
    function consume(uint256 amount) external;
    function burnToken(uint256 amount) external;
}

contract Breed is Context, Ownable {
    using SafeMath for uint256;
    IAlpaNFT alpaNFT;
    IAlpa20 aps;
    IAlpa20 alp;
    mapping(uint256 => uint256) consumptionApsQuantities;
    mapping(uint256 => uint256) consumptionAlpQuantities;
    uint256 public recastConsumptionAps = 4 * 10 ** 18;
    uint256 private _maxBreedTimes = 7;
    address private _validator;

    event BreedEvent(address indexed owner, uint256 indexed tokenId, uint256 indexed motherId, uint256 fatherId);

    event RecastEvent(address indexed owner, uint256 indexed tokenId);

    constructor (address AlpaNFTAddress, address APSTokenAddress, address ALPTokenAddress) {
        alpaNFT = IAlpaNFT(AlpaNFTAddress);
        aps = IAlpa20(APSTokenAddress);
        alp = IAlpa20(ALPTokenAddress);
        consumptionAlpQuantities[0] = 150 * 10 ** 18;
        consumptionAlpQuantities[1] = 300 * 10 ** 18;
        consumptionAlpQuantities[2] = 450 * 10 ** 18;
        consumptionAlpQuantities[3] = 750 * 10 ** 18;
        consumptionAlpQuantities[4] = 1200 * 10 ** 18;
        consumptionAlpQuantities[5] = 1950 * 10 ** 18;
        consumptionAlpQuantities[6] = 3150 * 10 ** 18;
        consumptionApsQuantities[0] = 2 * 10 ** 18;
        consumptionApsQuantities[1] = 2 * 10 ** 18;
        consumptionApsQuantities[2] = 2 * 10 ** 18;
        consumptionApsQuantities[3] = 2 * 10 ** 18;
        consumptionApsQuantities[4] = 2 * 10 ** 18;
        consumptionApsQuantities[5] = 2 * 10 ** 18;
        consumptionApsQuantities[6] = 2 * 10 ** 18;
    }

    function setRecastConsumptionAps(uint256 consume) public onlyOwner {
        recastConsumptionAps = consume;
    }

    function setConsumptionApsQuantities(uint8 breedCount, uint256 consume) public onlyOwner {
        consumptionApsQuantities[breedCount] = consume;
    }

    function setConsumptionAlpQuantities(uint8 breedCount, uint256 consume) public onlyOwner {
        consumptionAlpQuantities[breedCount] = consume;
    }

    function setMaxBreedTimes(uint256 maxBreedTimes) public onlyOwner {
        _maxBreedTimes = maxBreedTimes;
    }

    function setValidator(address validator) public onlyOwner {
        _validator = validator;
    }

    function breed(uint256[2] memory parentsId, bytes calldata sig) public payable returns(uint256) {
        // 判断所有权
        require(alpaNFT.ownerOf(parentsId[0]) == _msgSender() && alpaNFT.ownerOf(parentsId[1]) == _msgSender(), "AlpaKingdom: do not have alpas");
        // 判断年龄是否可以成熟
        bytes32 message = prefixed(keccak256(abi.encodePacked(parentsId[0], parentsId[1])));
        require(recoverSigner(message, sig) == _validator, "AlpaKingdom: invalid signature");

        // 判断生产次数
        uint256 motherBreedCount = alpaNFT.checkBreedTimes(parentsId[0]);
        uint256 fatherBreedCount = alpaNFT.checkBreedTimes(parentsId[1]);
        require(motherBreedCount < _maxBreedTimes && fatherBreedCount < _maxBreedTimes, "AlpaKingdom: breed too many times!");
        uint256 alpaTokenId = alpaNFT.breedMint(_msgSender(), parentsId);
        aps.consume((consumptionApsQuantities[motherBreedCount] + consumptionApsQuantities[fatherBreedCount]));
        alp.burnToken((consumptionAlpQuantities[motherBreedCount] + consumptionAlpQuantities[fatherBreedCount]));
        emit BreedEvent(_msgSender(), alpaTokenId, parentsId[0], parentsId[1]);
        return alpaTokenId;
    }

    function recast(uint256 tokenId) public payable returns(uint256) {
        // 判断所有权
        require(alpaNFT.ownerOf(tokenId) == _msgSender(), "AlpaKingdom: do not have alpas");

        // 消耗四个aps
        aps.consume(recastConsumptionAps);
        emit RecastEvent(_msgSender(), tokenId);
        return tokenId;
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        assert(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (fitrst byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

}
