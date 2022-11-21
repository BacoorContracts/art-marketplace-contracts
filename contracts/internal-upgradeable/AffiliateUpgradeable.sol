// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "oz-custom/contracts/oz-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IAffiliate.sol";

import "oz-custom/contracts/libraries/FixedPointMathLib.sol";

abstract contract AffiliateUpgradeable is IAffiliate, Initializable {
    using FixedPointMathLib for uint256;

    uint256 public constant WITHDRAWAL_THRESHOLD = 1 ether;
    uint256 private constant __PERCENTAGE_FRACTION = 10_000;

    mapping(address => uint16) public bonusRates;
    mapping(address => Bonus) public tokenBonuses;
    mapping(address => mapping(address => uint96)) public claimed;

    function __Affiliate_init(
        address[] calldata tokens_,
        uint256[] calldata frations_,
        address[] calldata beneficiaries_,
        uint256[] calldata affiliateBonuses_
    ) internal onlyInitializing {
        __Affiliate_init_unchained(
            tokens_,
            frations_,
            beneficiaries_,
            affiliateBonuses_
        );
    }

    function __Affiliate_init_unchained(
        address[] calldata tokens_,
        uint256[] calldata fractions_,
        address[] calldata beneficiaries_,
        uint256[] calldata affiliateBonuses_
    ) internal onlyInitializing {
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

    function withdrawBonus(address token_, address account_) external virtual;

    function _withdrawBonus(
        address token_,
        address account_
    ) internal returns (uint256 claimable) {
        claimable = withdrawableBonus(token_, account_);
        if (claimable == 0) revert Affiliate__CannotWithdraw();
        _updateClaimed(token_, account_, uint96(claimable));
    }

    function withdrawableBonus(
        address token_,
        address account_
    ) public view returns (uint256) {
        uint256 fraction = bonusRates[account_];
        if (fraction == 0) revert Affiliate__Unauthorized();
        uint256 bonus = uint256(tokenBonuses[token_].accumulated).mulDivDown(
            fraction,
            __PERCENTAGE_FRACTION
        );
        uint256 _claimed = claimed[token_][account_];
        uint256 claimable = bonus > _claimed ? bonus - _claimed : 0;
        return claimable >= WITHDRAWAL_THRESHOLD ? claimable : 0;
    }

    function _configAffiliate(address account_, uint16 bonusRate_) internal {
        bonusRates[account_] = bonusRate_;
    }

    function _updateAccumulatedBonus(address token_, uint256 volume_) internal {
        Bonus memory bonus = tokenBonuses[token_];
        if (bonus.fraction != 0) {
            bonus.accumulated += uint96(
                volume_.mulDivDown(bonus.fraction, __PERCENTAGE_FRACTION)
            );
            emit BonusAccumulated(token_, bonus.accumulated);
            tokenBonuses[token_].accumulated = bonus.accumulated;
        }
    }

    function _updateClaimed(
        address token_,
        address account_,
        uint96 claimed_
    ) internal {
        claimed[token_][account_] += claimed_;
        tokenBonuses[token_].accumulated += claimed_;

        emit Claimed(token_, account_, claimed_);
    }

    uint256[47] private __gap;
}
