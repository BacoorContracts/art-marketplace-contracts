// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/internal/Cloner.sol";
import "oz-custom/contracts/internal/FundForwarder.sol";
import "oz-custom/contracts/internal/MultiDelegatecall.sol";

import "./internal/Base.sol";

import "./interfaces/ITreasury.sol";
import "./interfaces/ICollectible721.sol";

contract NFTFactory is Base, Cloner, FundForwarder, MultiDelegatecall {
    /// @dev value is equal to keccak256("CollectibleCloner_v1")
    bytes32 public constant VERSION =
        0xa8c6a324d9e999a7a85f4a5b54b78927575d1be8226ddaf15e1dbd2dc8fdaec7;

    constructor(
        address implement_,
        IAuthority authority_,
        ITreasury vault_
    )
        payable
        Cloner(implement_)
        FundForwarder(address(vault_))
        Base(authority_, Roles.FACTORY_ROLE)
    {}

    function batchExecute(
        bytes[] calldata data_
    ) external returns (bytes[] memory) {
        return _multiDelegatecall(data_);
    }

    function setImplement(
        address implement_
    ) external override onlyRole(Roles.OPERATOR_ROLE) {
        emit ImplementChanged(implement(), implement_);
        _setImplement(implement_);
    }

    function clone(
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_,
        string calldata baseExtension_,
        uint256 mintPrice_,
        uint256 chainIdentifier_
    ) external returns (address) {
        // get rid of stack too deep
        _checkRole(Roles.OPERATOR_ROLE, _msgSender());
        return
            _clone(
                __saltOf(name_, symbol_),
                ICollectible721.init.selector,
                abi.encode(
                    authority(),
                    vault,
                    name_,
                    symbol_,
                    baseURI_,
                    baseExtension_,
                    mintPrice_,
                    chainIdentifier_
                )
            );
    }

    function cloneOf(
        string calldata name_,
        string calldata symbol_
    ) external view returns (address, bool) {
        bytes32 salt = keccak256(
            abi.encodePacked(name_, symbol_, address(this), VERSION)
        );
        return _cloneOf(salt);
    }

    function __saltOf(
        string calldata name_,
        string calldata symbol_
    ) private view returns (bytes32) {
        return
            keccak256(abi.encodePacked(name_, symbol_, address(this), VERSION));
    }
}
