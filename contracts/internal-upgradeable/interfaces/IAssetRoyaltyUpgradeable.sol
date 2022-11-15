// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/oz-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IAssetRoyaltyUpgradeable {
    event FeeChanged();

    function feeInfo()
        external
        view
        returns (IERC20Upgradeable feeToken, uint256 feeAmt);

    function setFee(IERC20Upgradeable fee_, uint256 feeAmt_) external;
}
