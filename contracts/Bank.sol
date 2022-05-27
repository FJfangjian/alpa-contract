// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface _IERC20 {
    function mint(address to, uint256 amount) external;
}

contract Bank is Pausable, Ownable {

    mapping(address => mapping(uint256 => bool)) usedNonces;

    address public alpaManager = msg.sender;

    address private _validator;

    event BankSuccess (address tokenAddr, string eventName, address sender, address receiver, uint256 amount, uint256 nonce);

    function setAlpaManager(address newAlpa) public onlyOwner {
        alpaManager = newAlpa;
    }

    function setValidator(address validator) public onlyOwner {
        _validator = validator;
    }

    function claim(address tokenAddress, string memory eventName, address receiver, uint256 amount, uint256 nonce, bytes memory sig) public {
        bytes32 message = prefixed(keccak256(abi.encodePacked(receiver, amount, nonce)));
        require(recoverSigner(message, sig) == _validator, "Bank: invalid signature");

        require(!usedNonces[tokenAddress][nonce], "Bank: nonce used");
        usedNonces[tokenAddress][nonce] = true;

        _IERC20(tokenAddress).mint(receiver, amount);
        emit BankSuccess(tokenAddress, eventName, address(0), msg.sender ,amount, nonce);
    }

    function withdraw(address tokenAddress, string memory eventName, address receiver, uint256 amount, uint256 nonce, bytes memory sig) public {
        bytes32 message = prefixed(keccak256(abi.encodePacked(receiver, amount, nonce)));
        require(recoverSigner(message, sig) == _validator, "Bank: invalid signature");

        require(!usedNonces[tokenAddress][nonce], "Bank: nonce used");
        usedNonces[tokenAddress][nonce] = true;


        IERC20(tokenAddress).transferFrom(alpaManager, msg.sender ,amount);
        emit BankSuccess(tokenAddress, eventName, alpaManager, msg.sender ,amount, nonce);
    }

    function receipt(address tokenAddress, string memory eventName, address sender, uint256 amount, uint256 nonce, bytes memory sig) public {
        bytes32 message = prefixed(keccak256(abi.encodePacked(sender, amount, nonce)));
        require(recoverSigner(message, sig) == _validator, "Bank: invalid signature");

        require(!usedNonces[tokenAddress][nonce], "Bank: nonce used");
        usedNonces[tokenAddress][nonce] = true;


        IERC20(tokenAddress).transferFrom(sender ,alpaManager, amount);
        emit BankSuccess(tokenAddress, eventName, sender , alpaManager, amount, nonce);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
    internal
    pure
    returns (address)
    {
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
