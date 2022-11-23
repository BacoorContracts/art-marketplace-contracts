// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import {ICollectible721} from "./interfaces/ICollectible721.sol";

import {IMarketplace} from "./interfaces/IMarketplace.sol";

contract ParamEncoder {
    function lenhBanNFT(
        address[] calldata nhungDongThanhToan_,
        uint256 giaDo_,
        address cho_,
        uint256 listingId
    ) external pure returns (bytes memory params, bytes memory result) {
        address user;
        address token;
        uint256 value;
        params = abi.encode(
            user,
            token,
            value,
            giaDo_,
            nhungDongThanhToan_,
            listingId
        );
        result = abi.encode(cho_, IMarketplace.listItem.selector, params);
    }

    function lenhMuaNFT(
        uint256 idSanPham_
    ) external pure returns (bytes memory) {
        address user;
        address token;
        uint256 value;
        return abi.encode(idSanPham_, user, token, value);
    }

    function inNFTCoGia(
        string calldata linkHinhAnh_
    ) external pure returns (bytes memory) {
        address user;
        address token;
        uint256 value;
        return abi.encode(user, token, value, linkHinhAnh_);
    }

    function getSellSelector() external pure returns (bytes4) {
        return IMarketplace.listItem.selector;
    }

    // function decode(bytes memory data_) external pure returns (address sender_, address token, uint256 value_, uint256 price, address[] memory tokens) {
    //     return abi.decode(data_, (address, address, uint256, uint256, address[]));
    // }

    // function concatData(address sender_, address token_, uint256 value_, bytes memory data_) external pure returns (bytes memory) {
    //     assembly {
    //         mstore(add(data_, 32), sender_)
    //         mstore(add(data_, 64), token_)
    //         mstore(add(data_, 96), value_)
    //     }
    //     return data_;
    // }
}
