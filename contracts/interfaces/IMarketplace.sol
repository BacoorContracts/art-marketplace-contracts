// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/oz-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "oz-custom/contracts/oz-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "oz-custom/contracts/oz-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IMarketplace {
    error Marketplace__Unauthorized();
    error Marketplace__UnsupportedNFT();
    error Marketplace__InvalidListingId();
    error Marketplace__InsufficientAmount();
    error Marketplace__UnsupportedPayment(IERC20Upgradeable);

    struct Item {
        IERC721Upgradeable nft;
        address seller;
        uint256 tokenId;
        uint256 usdPrice;
        IERC20Upgradeable[] payments;
    }

    event Listed(uint256 indexed listingId, Item indexed item);

    event ItemBought(
        uint256 indexed listingId,
        address indexed buyer,
        IERC20Upgradeable indexed payment,
        uint256 payout
    );

    event Unlisted(uint256 indexed listingId, Item indexed item);

    event ItemModified(uint256 indexed listingId, Item indexed item);

    function buy(
        address buyer_,
        IERC20Upgradeable payment_,
        uint256 value_,
        uint256 listingId_
    ) external;

    function listItem(
        uint256 listingId_,
        address seller_,
        IERC721Upgradeable nft_,
        uint256 tokenId_,
        uint256 usdPrice_,
        IERC20Upgradeable[] calldata payments_
    ) external;

    function modifyListingItem(
        uint256 listingId_,
        Item calldata item_
    ) external;

    function unlistItem(uint256 listingId_) external;

    function order(uint256 listingId_) external view returns (Item memory);

    function sellerOrders(
        address account_
    ) external view returns (Item[] memory orders);
}
