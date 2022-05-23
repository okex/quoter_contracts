// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC20Transformer.sol";
import "./bridges/IBridgeAdapter.sol";
import "../libs/LibERC20Transformer.sol";
import "../libs/LibTransformERC20RichErrors.sol";
import "../libs/LibRichErrors.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface INativeOrdersFeature {
    function fillLimitOrder() external payable;
}

// support rfq, limit order and bridge order(Dex order)
contract FillQuoteTransformer is IERC20Transformer {
    using SafeMath for uint256;
    using LibERC20Transformer for IERC20;
    using LibRichErrors for bytes;

    /// @dev The BridgeAdapter address
    IBridgeAdapter public immutable bridgeAdapter;

    /// @dev The exchange proxy contract.
    INativeOrdersFeature public immutable zeroEx;

    /// @dev Whether we are performing a market sell or buy.
    enum Side {
        Sell,
        Buy
    }

    enum OrderType {
        Bridge,
        Limit,
        Rfq
    }

    struct TransformData {
        Side side;
        IERC20 sellToken;
        IERC20 buyToken;
        IBridgeAdapter.BridgeOrder bridgeOrder;
        uint256 fillAmount;
    }

    struct FillOrderResults {
        // The amount of taker tokens sold, according to balance checks.
        uint256 takerTokenSoldAmount;
        // The amount of maker tokens sold, according to balance checks.
        uint256 makerTokenBoughtAmount;
        // The amount of protocol fee paid.
        uint256 protocolFeePaid;
    }

    constructor(IBridgeAdapter bridgeAdapter_, INativeOrdersFeature zeroEx_) {
        bridgeAdapter = bridgeAdapter_;
        zeroEx = zeroEx_;
    }

    function transform(TransformContext calldata context) external override {
        TransformData memory data = abi.decode(context.data, (TransformData));
        // Validate data fields.
        if (data.sellToken.isTokenETH() || data.buyToken.isTokenETH()) {
            LibTransformERC20RichErrors
                .InvalidTransformDataError(
                    LibTransformERC20RichErrors
                        .InvalidTransformDataErrorCode
                        .INVALID_TOKENS,
                    context.data
                )
                .rrevert();
        }

        uint256 takerTokenBalanceRemaining = data.sellToken.getTokenBalanceOf(
            address(this)
        );
        data.fillAmount = Math.min(
            _normalizeFillAmount(data.fillAmount, takerTokenBalanceRemaining),
            context.tokenLimits
        );

        // Fill the order.
        FillOrderResults memory results;
        results = _fillBridgeOrder(data.bridgeOrder, data);

        require(
            results.takerTokenSoldAmount == data.fillAmount,
            "order is not fulfilled completly!"
        );
    }

    // Fill a single bridge order.
    function _fillBridgeOrder(
        IBridgeAdapter.BridgeOrder memory order,
        TransformData memory data
    ) private returns (FillOrderResults memory results) {
        uint256 takerTokenFillAmount = _computeTakerTokenFillAmount(
            data,
            order.takerTokenAmount,
            order.makerTokenAmount,
            0
        );

        (bool success, bytes memory resultData) = address(bridgeAdapter)
            .delegatecall(
                abi.encodeWithSelector(
                    IBridgeAdapter.trade.selector,
                    order,
                    data.sellToken,
                    data.buyToken,
                    takerTokenFillAmount
                )
            );
        if (success) {
            results.makerTokenBoughtAmount = abi.decode(resultData, (uint256));
            results.takerTokenSoldAmount = takerTokenFillAmount;
        }
    }

    // Compute the next taker token fill amount of a generic order.
    function _computeTakerTokenFillAmount(
        TransformData memory data,
        uint256 orderTakerAmount,
        uint256 orderMakerAmount,
        uint256 orderTakerTokenFeeAmount
    ) private pure returns (uint256 takerTokenFillAmount) {
        if (data.side == Side.Sell) {
            takerTokenFillAmount = data.fillAmount;
            if (orderTakerTokenFeeAmount != 0) {
                takerTokenFillAmount = takerTokenFillAmount
                    .mul(orderTakerAmount)
                    .div(orderTakerAmount.add(orderTakerTokenFeeAmount));
            }
        } else {
            // Buy
            takerTokenFillAmount = data.fillAmount.mul(orderTakerAmount).div(
                orderMakerAmount
            );
        }
        return Math.min(takerTokenFillAmount, orderTakerAmount);
    }

    // Convert possible proportional values to absolute quantities.
    function _normalizeFillAmount(uint256 rawAmount, uint256 balance)
        private
        pure
        returns (uint256 normalized)
    {
        return Math.min(rawAmount, balance);
    }
}
