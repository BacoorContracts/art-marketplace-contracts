// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./internal-upgradeable/BaseUpgradeable.sol";
import "./internal-upgradeable/AffiliateUpgradeable.sol";

import "oz-custom/contracts/internal-upgradeable/ProtocolFeeUpgradeable.sol";
import "oz-custom/contracts/internal-upgradeable/FundForwarderUpgradeable.sol";

import "./interfaces/IMarketplace.sol";

import "oz-custom/contracts/libraries/SSTORE2.sol";
import "oz-custom/contracts/libraries/FixedPointMathLib.sol";
import "oz-custom/contracts/oz-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract Marketplace is
    IMarketplace,
    BaseUpgradeable,
    FundForwarderUpgradeable,
    AffiliateUpgradeable
{
    using SSTORE2 for *;
    using FixedPointMathLib for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    /// @dev value is equal to keccak256("Marketplace_v1")
    bytes32 public constant VERSION =
        0x58166ef1331604f9d1096f21021b62681af867d090bf7bef436de91286e1ed67;

    uint256 public constant PERCENTAGE_FRACTION = 10_000;

    mapping(uint256 => bytes32) private __listedItems;
    mapping(address => EnumerableSetUpgradeable.Bytes32Set)
        private __sellerOrders;

    // /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() payable {
    //     _disableInitializers();
    // }

    function init(
        IAuthority authority_,
        ITreasury treasury_,
        address[] calldata tokens_,
        uint256[] calldata fractions_,
        address[] calldata beneficiaries_,
        uint256[] calldata affiliateBonuses_
    ) external initializer {
        __FundForwarder_init_unchained(address(treasury_));
        __Base_init_unchained(authority_, Roles.TREASURER_ROLE);
        __Affiliate_init_unchained(
            tokens_,
            fractions_,
            beneficiaries_,
            affiliateBonuses_
        );
    }

    function recoverNFTs(IERC721EnumerableUpgradeable token_) external {
        uint256 length = token_.balanceOf(address(this));
        for (uint256 i; i < length; ) {
            token_.safeTransferFrom(
                address(this),
                vault,
                token_.tokenOfOwnerByIndex(address(this), i)
            );
            unchecked {
                ++i;
            }
        }
    }

    function recoverNFT(IERC721Upgradeable token_, uint256 tokenId_) external {
        token_.safeTransferFrom(address(this), vault, tokenId_);
    }

    function withdrawBonus(address token_, address account_) external override {
        uint256 claimable = _withdrawBonus(token_, account_);
        IWithdrawableUpgradeable(vault).withdraw(token_, account_, claimable);
    }

    function configAffiliate(
        address[] calldata tokens_,
        uint256[] calldata fractions_,
        address[] calldata beneficiaries_,
        uint256[] calldata affiliateBonuses_
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        uint256 length = tokens_.length;
        if (length != fractions_.length) revert Affiliate__LengthMismatch();

        uint256[] memory tmp = fractions_;

        uint16[] memory fractions;
        assembly {
            fractions := tmp
        }
        for (uint256 i; i < length; ) {
            tokenBonuses[tokens_[i]].fraction = fractions[i];
            unchecked {
                ++i;
            }
        }

        length = beneficiaries_.length;
        if (length != affiliateBonuses_.length)
            revert Affiliate__LengthMismatch();
        tmp = affiliateBonuses_;
        assembly {
            fractions := tmp
        }
        for (uint256 i; i < length; ) {
            _configAffiliate(beneficiaries_[i], fractions[i]);
            unchecked {
                ++i;
            }
        }
    }

    function updateTreasury(
        ITreasury treasury_
    ) external override onlyRole(Roles.OPERATOR_ROLE) {
        emit VaultUpdated(vault, address(treasury_));
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
        _updateAccumulatedBonus(address(payment_), payout);

        emit ItemBought(listingId_, buyer_, payment_, payout);
    }

    function listItem(
        address seller_,
        IERC721Upgradeable nft_,
        uint256 tokenId_,
        uint256 usdPrice_,
        IERC20Upgradeable[] calldata payments_,
        uint256 listingId
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

        Item memory item = Item({
            nft: nft_,
            seller: seller_,
            payments: payments_,
            tokenId: tokenId_,
            usdPrice: usdPrice_
        });

        __listItem(seller_, listingId, item);

        emit Listed(
            listingId,
            address(item.nft),
            item.seller,
            item.tokenId,
            item.usdPrice,
            item.payments
        );
    }

    function modifyListingItem(
        uint256 listingId_,
        Item calldata item_
    ) external {
        bytes32 itemPtr = __listedItems[listingId_];
        if (itemPtr == 0) revert Marketplace__InvalidListingId();

        Item memory item = abi.decode(itemPtr.read(), (Item));
        if (item.seller != _msgSender()) revert Marketplace__Unauthorized();

        __listedItems[listingId_] = abi.encode(item_).write();

        emit ItemModified(listingId_, item.usdPrice, item.payments);
    }

    function unlistItem(uint256 listingId_) external {
        bytes32 itemPtr = __listedItems[listingId_];
        if (itemPtr == 0) revert Marketplace__InvalidListingId();
        address user = _msgSender();
        Item memory item = abi.decode(itemPtr.read(), (Item));
        if (item.seller != user) revert Marketplace__Unauthorized();

        __unlistItem(user, listingId_, itemPtr);

        IWithdrawableUpgradeable(vault).withdraw(
            address(item.nft),
            user,
            item.tokenId
        );

        emit Unlisted(listingId_);
    }

    function order(uint256 listingId_) external view returns (Item memory) {
        return abi.decode(__listedItems[listingId_].read(), (Item));
    }

    function sellerOrders(
        address account_
    ) external view returns (Item[] memory orders) {
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

    uint256[48] private __gap;
}
