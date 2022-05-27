// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract ALPToken is ERC20, ERC20Burnable, Ownable, AccessControl {

    bytes32 public constant OPT_ROLE = keccak256("OPT_ROLE");

    constructor() ERC20("ALPToken", "ALP") {
        // init role config
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(OPT_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(OPT_ROLE, msg.sender), "ALP Token: only minter!");
        _mint(to, amount);
    }

    function consume(uint256 amount) public {
        require(hasRole(OPT_ROLE, msg.sender), "ALP Token: not alpa consume");
        _transfer(tx.origin, owner(), amount);
    }

    function burnToken(uint256 amount) public {
        require(hasRole(OPT_ROLE, msg.sender), "ALP Token: not alpa consume");
        _burn(tx.origin, amount);
    }
}
