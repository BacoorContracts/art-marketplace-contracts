// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./internal-upgradeable/BaseUpgradeable.sol";

import "oz-custom/contracts/internal-upgradeable/ProtocolFeeUpgradeable.sol";
import "oz-custom/contracts/internal-upgradeable/FundForwarderUpgradeable.sol";
import "oz-custom/contracts/internal-upgradeable/MultiDelegatecallUpgradeable.sol";

import "oz-custom/contracts/oz-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "oz-custom/contracts/oz-upgradeable/token/ERC721/extensions/ERC721PermitUpgradeable.sol";
import "oz-custom/contracts/oz-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {
    ERC721TokenReceiverUpgradeable,
    ERC721EnumerableUpgradeable
} from "oz-custom/contracts/oz-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import "./interfaces/ICollectible721.sol";

import "oz-custom/contracts/libraries/FixedPointMathLib.sol";

contract Collectible721 is
    ICollectible721,
    BaseUpgradeable,
    ProtocolFeeUpgradeable,
    ERC721PermitUpgradeable,
    FundForwarderUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    MultiDelegatecallUpgradeable,
    ERC721TokenReceiverUpgradeable
{
    using SSTORE2 for *;
    using StringLib for uint256;
    using FixedPointMathLib for uint256;

    /// @dev value is equal to keccak256("Collectible721_v1")
    bytes32 public constant VERSION =
        0x9de63d708ee09a8f840a47cc975044d19e4c3537fe6b165971d829e6619e0ffa;

    uint256 public constant CHAIN_ID_BIT_SLOT = 4;

    uint256 public mintPrice;
    uint256 public chainIdentifier;
    uint256 public tokenIdTracker;

    string public baseExtension;

    function init(
        IAuthority authority_,
        ITreasury treasury_,
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_,
        string calldata baseExtension_,
        uint256 mintPrice_,
        uint256 chainIdentifier_
    ) external initializer {
        mintPrice = mintPrice_;
        baseExtension = baseExtension_;
        chainIdentifier = chainIdentifier_;

        __MultiDelegatecall_init_unchained();
        __Base_init_unchained(authority_, 0);
        __ERC721Permit_init(name_, symbol_);
        __ERC721URIStorage_init_unchained(baseURI_);
        __FundForwarder_init_unchained(address(treasury_));
    }

    function recoverNFTs() external {
        uint256 length = balanceOf(address(this));
        for (uint256 i; i < length; ) {
            safeTransferFrom(
                address(this),
                vault,
                tokenOfOwnerByIndex(address(this), i)
            );
            unchecked {
                ++i;
            }
        }
    }

    function batchExecute(
        bytes[] calldata data_
    ) external returns (bytes[] memory) {
        return _multiDelegatecall(data_);
    }

    function mint(
        address to_,
        string calldata tokenURI_
    ) external onlyRole(Roles.MINTER_ROLE) returns (uint256 tokenId_) {
        tokenId_ = __mint(to_, tokenURI_);
    }

    function mint(
        string calldata tokenURI_,
        address to_,
        address paymentToken_,
        uint256 value_
    ) external onlyRole(Roles.PROXY_ROLE) returns (uint256 tokenId_) {
        ITreasury treasury = ITreasury(vault);
        if (!treasury.supportedPayment(paymentToken_))
            revert Collectible721__UnsupportedPayments();
        if (
            value_.mulDivUp(treasury.priceOf(paymentToken_), 1 ether) <
            mintPrice
        ) revert Collectible721__InsufficientAmount();

        tokenId_ = __mint(to_, tokenURI_);
    }

    function mintBatch(
        address to_,
        uint256 quantity_,
        string[] calldata tokenURIs_
    ) external onlyRole(Roles.MINTER_ROLE) returns (uint256[] memory tokenIds) {
        tokenIds = __mintBatch(to_, quantity_, tokenURIs_);
    }

    function mintBatch(
        string[] calldata tokenURIs_,
        address to_,
        uint256 quantity_,
        address paymentToken_,
        uint256 value_
    ) external onlyRole(Roles.PROXY_ROLE) returns (uint256[] memory tokenIds) {
        ITreasury treasury = ITreasury(vault);
        if (!treasury.supportedPayment(paymentToken_))
            revert Collectible721__UnsupportedPayments();
        if (
            value_.mulDivUp(ITreasury(vault).priceOf(paymentToken_), 1 ether) <
            mintPrice * tokenURIs_.length
        ) revert Collectible721__InsufficientAmount();

        tokenIds = __mintBatch(to_, quantity_, tokenURIs_);
    }

    function updateTreasury(
        ITreasury treasury_
    ) external override onlyRole(Roles.OPERATOR_ROLE) {
        emit VaultUpdated(vault, address(treasury_));
        _changeVault(address(treasury_));
    }

    function setBaseURI(
        string calldata baseURI_
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        _setBaseURI(baseURI_);
    }

    function supportsInterface(
        bytes4 interfaceId_
    )
        public
        view
        override(
            ERC721Upgradeable,
            IERC165Upgradeable,
            ERC721EnumerableUpgradeable
        )
        returns (bool)
    {
        return
            type(IERC165Upgradeable).interfaceId == interfaceId_ ||
            super.supportsInterface(interfaceId_);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return ERC721TokenReceiverUpgradeable.onERC721Received.selector;
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    ERC721URIStorageUpgradeable.tokenURI(tokenId),
                    baseExtension
                )
            );
    }

    function _burn(
        uint256 tokenId_
    ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        ERC721URIStorageUpgradeable._burn(tokenId_);
    }

    function _setBaseURI(string calldata baseURI_) internal {
        _baseTokenURIPtr = bytes(baseURI_).write();
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    )
        internal
        virtual
        override(ERC721EnumerableUpgradeable, ERC721Upgradeable)
    {
        _requireNotPaused();
        super._beforeTokenTransfer(from_, to_, tokenId_);

        _checkBlacklist(from_);
        _checkBlacklist(to_);
    }

    function __mint(
        address to_,
        string calldata tokenURI_
    ) private returns (uint256 tokenId_) {
        unchecked {
            _safeMint(
                to_,
                tokenId_ =
                    (++tokenIdTracker << CHAIN_ID_BIT_SLOT) |
                    chainIdentifier
            );
        }
        if (bytes(tokenURI_).length != 0) _setTokenURI(tokenId_, tokenURI_);
    }

    function __mintBatch(
        address to_,
        uint256 quantity_,
        string[] calldata tokenURIs_
    ) private returns (uint256[] memory tokenIds) {
        uint256 mintAmt = tokenURIs_.length;
        if (mintAmt > 0 && (quantity_ != mintAmt))
            revert Collectible721__LengthMismatch(); // all or nothing
        tokenIds = new uint256[](mintAmt);

        uint256 _chainIdentifier = chainIdentifier;
        uint256 _tokenIdTracker = tokenIdTracker;
        uint256 chainIdBitSlot = CHAIN_ID_BIT_SLOT;

        for (uint256 i; i < mintAmt; ) {
            if (bytes(tokenURIs_[i]).length != 0)
                _setTokenURI(tokenIds[i], tokenURIs_[i]);
            unchecked {
                _mint(
                    to_,
                    tokenIds[i] =
                        (++_tokenIdTracker << chainIdBitSlot) |
                        _chainIdentifier
                );
                ++i;
            }
        }

        tokenIdTracker = _tokenIdTracker;
    }

    uint256[46] private __gap;
}
