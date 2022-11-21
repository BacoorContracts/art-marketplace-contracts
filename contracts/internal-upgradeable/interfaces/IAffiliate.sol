// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IAffiliate {
    error Affiliate__Unauthorized();
    error Affiliate__LimitExceeded();
    error Affiliate__CannotWithdraw();
    error Affiliate__LengthMismatch();

    struct Bonus {
        uint16 fraction;
        uint96 accumulated;
    }

    event Claimed(
        address indexed token,
        address indexed account,
        uint256 indexed claimedAmount
    );

    event BonusAccumulated(
        address indexed token,
        uint256 indexed payout,
        uint256 indexed accumulated
    );

    function withdrawBonus(address token_, address account_) external;

    function withdrawableBonus(
        address token_,
        address account_
    ) external view returns (uint256);
}
