// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface ICollectible721 {
    error Collectible721__InsufficientAmount();
    error Collectible721__UnsupportedPayments();

    function recoverNFTs() external;

    function batchExecute(
        bytes[] calldata data_
    ) external returns (bytes[] memory);

    function mint(
        address to_,
        string calldata tokenURI_
    ) external returns (uint256);

    function mint(
        string calldata tokenURI_,
        address to_,
        address paymentToken_,
        uint256 value_
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

    event Unlisted(uint256 indexed listingId, Item indexed item);

    event ItemModified(uint256 indexed listingId, Item indexed item);

    function buy(
        uint256 listingId_,
        address buyer_,
        IERC20Upgradeable payment_,
        uint256 value_
    ) external;

    function listItem(
        IERC20Upgradeable[] calldata payments_,
        uint256 usdPrice_,
        address seller_,
        IERC721Upgradeable nft_,
        uint256 tokenId_
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

contract ParamEncoder {
    function lenhBanNFT(
        address[] calldata nhungDongThanhToan_,
        uint256 giaDo_,
        address cho_
    ) external pure returns (bytes memory) {
        address user;
        address token;
        uint256 value;
        bytes memory params = abi.encode(
            user,
            token,
            value,
            nhungDongThanhToan_,
            giaDo_
        );
        return abi.encode(cho_, IMarketplace.listItem.selector, params);
    }

    function lenhMuaNFT(
        uint256 idSanPham_
    ) external pure returns (bytes memory) {
        address user;
        address token;
        uint256 value;
        return abi.encode(user, token, value, idSanPham_);
    }

    function inNFTCoGia(
        string calldata linkHinhAnh_
    ) external pure returns (bytes memory) {
        address user;
        address token;
        uint256 value;
        return abi.encode(user, token, value, linkHinhAnh_);
    }
}
