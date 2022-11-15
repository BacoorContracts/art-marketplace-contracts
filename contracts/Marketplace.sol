// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./internal-upgradeable/BaseUpgradeable.sol";

import "oz-custom/contracts/internal-upgradeable/ProtocolFeeUpgradeable.sol";
import "oz-custom/contracts/internal-upgradeable/FundForwarderUpgradeable.sol";

import "./interfaces/IMarketplace.sol";

import "oz-custom/contracts/libraries/SSTORE2.sol";
import "oz-custom/contracts/libraries/FixedPointMathLib.sol";
import "oz-custom/contracts/oz-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract Marketplace is
    IMarketplace,
    BaseUpgradeable,
    FundForwarderUpgradeable
{
    using SSTORE2 for *;
    using FixedPointMathLib for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    /// @dev value is equal to keccak256("Marketplace_v1")
    bytes32 public constant VERSION =
        0x58166ef1331604f9d1096f21021b62681af867d090bf7bef436de91286e1ed67;

    mapping(uint256 => bytes32) private __listedItems;
    mapping(address => EnumerableSetUpgradeable.Bytes32Set)
        private __sellerOrders;

    function init(IAuthority authority_, ITreasury treasury_)
        external
        initializer
    {
        __Base_init_unchained(authority_, Roles.TREASURER_ROLE);
        __FundForwarder_init_unchained(address(treasury_));
    }

    function updateTreasury(ITreasury treasury_)
        external
        override
        onlyRole(Roles.OPERATOR_ROLE)
    {
        _changeVault(address(treasury_));
    }

    function buy(
        uint256 listingId_,
        address buyer_,
        IERC20Upgradeable payment_,
        uint256 value_
    ) external onlyRole(Roles.PROXY_ROLE) {
        bytes32 itemPtr = __listedItems[listingId_];
        if (itemPtr == 0) revert Marketplace__InvalidListingId();
        Item memory item = abi.decode(itemPtr.read(), (Item));
        __unlistItem(item.seller, listingId_, itemPtr);

        uint256 length = item.payments.length;
        bool contains;
        for (uint256 i; i < length; ) {
            if (item.payments[i] == payment_) {
                contains = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!contains) revert Marketplace__UnsupportedPayment(payment_);

        address _vault = vault;
        // usd per token
        uint256 unitPrice = ITreasury(_vault).priceOf(address(payment_));
        // tokens to usd
        uint256 usdPrice = value_.mulDivDown(unitPrice, 1 ether);
        if (usdPrice < item.usdPrice) revert Marketplace__InsufficientAmount();
        // amount to pay
        uint256 payout = item.usdPrice.mulDivDown(1 ether, unitPrice);
        IWithdrawableUpgradeable(_vault).withdraw(
            address(payment_),
            item.seller,
            payout
        );

        // refund
        unchecked {
            if (payout < value_)
                IWithdrawableUpgradeable(_vault).withdraw(
                    address(payment_),
                    item.seller,
                    value_ - payout // cannot underflow
                );
        }

        // transfer nft
        IWithdrawableUpgradeable(_vault).withdraw(
            address(item.nft),
            buyer_,
            item.tokenId
        );
    }

    function listItem(
        IERC20Upgradeable[] calldata payments_,
        uint256 usdPrice_,
        address seller_,
        IERC721Upgradeable nft_,
        uint256 tokenId_
    ) external onlyRole(Roles.PROXY_ROLE) {
        if (!_hasRole(Roles.PROXY_ROLE, address(nft_)))
            revert Marketplace__UnsupportedNFT();

        uint256 length = payments_.length;
        ITreasury treasury = ITreasury(vault);
        for (uint256 i; i < length; ) {
            if (!treasury.supportedPayment(address(payments_[i])))
                revert Marketplace__UnsupportedPayment(payments_[i]);
            unchecked {
                ++i;
            }
        }

        uint256 listingId = uint256(
            keccak256(abi.encode(seller_, nft_, tokenId_, payments_, usdPrice_))
        );

        Item memory item = Item({
            nft: nft_,
            seller: seller_,
            payments: payments_,
            tokenId: tokenId_,
            usdPrice: usdPrice_
        });

        __listItem(seller_, listingId, item);

        emit Listed(listingId, item);
    }

    function modifyListingItem(uint256 listingId_, Item calldata item_)
        external
    {
        bytes32 itemPtr = __listedItems[listingId_];
        if (itemPtr == 0) revert Marketplace__InvalidListingId();

        Item memory item = abi.decode(itemPtr.read(), (Item));
        if (item.seller != _msgSender()) revert Marketplace__Unauthorized();

        __listedItems[listingId_] = abi.encode(item_).write();

        emit ItemModified(listingId_, item_);
    }

    function unlistItem(uint256 listingId_) external {
        bytes32 itemPtr = __listedItems[listingId_];
        if (itemPtr == 0) revert Marketplace__InvalidListingId();
        address user = _msgSender();
        Item memory item = abi.decode(itemPtr.read(), (Item));
        if (item.seller != user) revert Marketplace__Unauthorized();

        __unlistItem(user, listingId_, itemPtr);

        emit Unlisted(listingId_, item);
    }

    function order(uint256 listingId_) external view returns (Item memory) {
        return abi.decode(__listedItems[listingId_].read(), (Item));
    }

    function sellerOrders(address account_)
        external
        view
        returns (Item[] memory orders)
    {
        uint256 length = __sellerOrders[account_].length();
        orders = new Item[](length);

        for (uint256 i; i < length; ) {
            orders[i] = abi.decode(
                __sellerOrders[account_].at(i).read(),
                (Item)
            );
            unchecked {
                ++i;
            }
        }
    }

    function __listItem(
        address seller_,
        uint256 listingId_,
        Item memory item_
    ) private {
        bytes32 itemPtr = abi.encode(item_).write();
        __listedItems[listingId_] = itemPtr;
        __sellerOrders[seller_].add(itemPtr);
    }

    function __unlistItem(
        address seller_,
        uint256 listingId_,
        bytes32 itemPtr_
    ) private {
        delete __listedItems[listingId_];
        __sellerOrders[seller_].remove(itemPtr_);
    }
}
