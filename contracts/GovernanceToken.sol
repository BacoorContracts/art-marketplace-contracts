// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/oz-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {
    ERC20PermitUpgradeable
} from "oz-custom/contracts/oz-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

import "./internal-upgradeable/BaseUpgradeable.sol";
import "oz-custom/contracts/internal-upgradeable/FundForwarderUpgradeable.sol";

import "./interfaces/IAM20.sol";
import "./interfaces/ITreasury.sol";

contract AM20 is
    IAM20,
    BaseUpgradeable,
    ERC20PermitUpgradeable,
    ERC20BurnableUpgradeable,
    FundForwarderUpgradeable
{
    ///@dev value is equal to keccak256("AM20_v1")
    bytes32 public constant VERSION =
        0x6e01d039b636caadd442e5221671597494f73a11123c34d2dfbc5caa7fbc5e3e;

    constructor() payable {
        _disableInitializers();
    }

    function init(
        IAuthority authority_,
        ITreasury treasury_,
        string calldata name_,
        string calldata symbol_,
        uint256 decimals_
    ) external initializer {
        __ERC20Permit_init(name_);
        __Base_init_unchained(authority_, 0);
        __FundForwarder_init_unchained(address(treasury_));
        __ERC20_init_unchained(name_, symbol_, decimals_);
    }

    function mint(
        address to_,
        uint256 amount_
    ) external onlyRole(Roles.MINTER_ROLE) {
        _mint(to_, amount_ * 10 ** decimals);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        _requireNotPaused();

        _checkBlacklist(to);
        _checkBlacklist(from);
        _checkBlacklist(_msgSender());

        super._beforeTokenTransfer(from, to, amount);
    }

    function updateTreasury(
        ITreasury treasury_
    ) external override onlyRole(Roles.OPERATOR_ROLE) {
        emit VaultUpdated(vault, address(treasury_));
        _changeVault(address(treasury_));
    }
}
