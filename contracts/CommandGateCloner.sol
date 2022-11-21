// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/internal/Cloner.sol";
import "oz-custom/contracts/internal/FundForwarder.sol";
import "oz-custom/contracts/internal/MultiDelegatecall.sol";

import "./internal/Base.sol";

import "./interfaces/ITreasury.sol";

contract CommandGateCloner is Base, Cloner, FundForwarder, MultiDelegatecall {
    /// @dev value is equal to keccak256("CommandGateCloner_v1")
    bytes32 public constant VERSION =
        0x7741d18da450db89c34533de032674773e1f4a87eac85f2202be103d4c8d55ab;

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
        uint256 id_
    ) external onlyRole(Roles.OPERATOR_ROLE) returns (address) {
        return _clone(__saltOf(id_), 0, "");
    }

    function __saltOf(uint256 id_) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    id_,
                    authority(),
                    vault,
                    address(this),
                    VERSION
                )
            );
    }
}
