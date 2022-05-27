// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract APSToken is ERC20Capped, ERC20Burnable, Ownable, AccessControl {

    bytes32 public constant OPT_ROLE = keccak256("OPT_ROLE");

    constructor () ERC20("APSToken", "APS") ERC20Capped(100000000 * 10 ** 18) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(OPT_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(OPT_ROLE, msg.sender), "APS Token: only minter!");
        super._mint(to, amount);
    }

    function consume(uint256 amount) public {
        require(hasRole(OPT_ROLE, msg.sender), "APS Token: not alpa consume");
        _transfer(tx.origin, owner(), amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    function burnToken(uint256 amount) public {
        require(hasRole(OPT_ROLE, msg.sender), "ALP Token: not alpa consume");
        _burn(tx.origin, amount);
    }
}
