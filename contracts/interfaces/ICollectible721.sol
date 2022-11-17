// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ITreasury.sol";
import "./IAuthority.sol";

interface ICollectible721 {
    error Collectible721__InsufficientAmount();
    error Collectible721__UnsupportedPayments();

    function init(
        IAuthority authority_,
        ITreasury treasury_,
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_,
        string calldata baseExtension_,
        uint256 mintPrice_,
        uint256 chainIdentifier_
    ) external;

    function recoverNFTs() external;

    function batchExecute(
        bytes[] calldata data_
    ) external returns (bytes[] memory);

    function mint(
        address to_,
        string calldata tokenURI_
    ) external returns (uint256);

    function mint(
        address to_,
        address paymentToken_,
        uint256 value_,
        string calldata tokenURI_
    ) external returns (uint256);

    function mintBatch(
        address to_,
        string[] calldata tokenURIs_
    ) external returns (uint256[] memory);

    function mintBatch(
        string[] calldata tokenURIs_,
        address to_,
        address paymentToken_,
        uint256 value_
    ) external returns (uint256[] memory);

    function setBaseURI(string calldata baseURI_) external;
}
