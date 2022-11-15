// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IFactoryUpgradeable {
    error Factory__CloneFailed();

    event NewInstance(
        address indexed implement_,
        address indexed clone_,
        bytes32 indexed salt,
        bytes4 interfaceId
    );
}
