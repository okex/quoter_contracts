// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/IMultiplexFeature.sol";
import "./multiplex/MultiplexTransformERC20.sol";
import "./multiplex/MultiplexQuoter.sol";

contract MultiplexFeature is
    IMultiplexFeature,
    MultiplexTransformERC20,
    MultiplexQuoter
{
    using SafeMath for uint256;
    using Math for uint256;
    using SafeERC20 for IERC20;
    /// @dev The highest bit of a uint256 value.
    uint256 private constant HIGH_BIT = 2**255;
    /// @dev Mask of the lower 255 bits of a uint256 value.
    uint256 private constant LOWER_255_BITS = HIGH_BIT - 1;

    function _executeBatchSell(BatchSellParams memory params)
        private
        returns (BatchSellState memory state)
    {
        for (uint256 i = 0; i < params.calls.length; ++i) {
            if (state.soldAmount >= params.sellAmount) {
                break;
            }
            BatchSellSubcall memory subcall = params.calls[i];
            uint256 inputTokenAmount = _normalizeSellAmount(
                subcall.sellAmount,
                params.sellAmount,
                state.soldAmount
            );
            if (i == params.calls.length - 1) {
                // use up remain tokens
                inputTokenAmount = params.sellAmount - state.soldAmount;
            }
            if (subcall.id == MultiplexSubcall.MultiHopSell) {
                _nestedMultiHopSell(
                    state,
                    params,
                    subcall.data,
                    inputTokenAmount
                );
            } else if (subcall.id == MultiplexSubcall.TransformERC20) {
                _batchSellTransformERC20(
                    state,
                    params,
                    subcall.data,
                    inputTokenAmount
                );
            } else if (subcall.id == MultiplexSubcall.Quoter) {
                _batchSellQuote(state, params, subcall.data, inputTokenAmount);
            } else {
                revert("MultiplexFeature::_executeBatchSell/INVALID_SUBCALL");
            }
        }

        require(
            state.soldAmount == params.sellAmount,
            "MultiplexFeature::_executeBatchSell/INCORRECT_AMOUNT_SOLD"
        );
    }

    function _executeMultiHopSell(MultiHopSellParams memory params)
        private
        returns (MultiHopSellState memory state)
    {
        state.outputTokenAmount = params.sellAmount;
        state.from = computeHopTarget(params, 0);
        // If the input tokens are currently held by `msg.sender` but
        // the first hop expects them elsewhere, perform a `transferFrom`.
        if (state.from != msg.sender) {
            IERC20(params.tokens[0]).safeTransferFrom(
                msg.sender,
                state.from,
                params.sellAmount
            );
        }

        for (
            state.hopIndex = 0;
            state.hopIndex < params.calls.length;
            ++state.hopIndex
        ) {
            MultiHopSellSubcall memory subcall = params.calls[state.hopIndex];
            state.to = computeHopTarget(params, state.hopIndex + 1);
            if (subcall.id == MultiplexSubcall.BatchSell) {
                _nestedBatchSell(state, params, subcall.data);
            } else {
                revert("MultiplexFeature::_executeBatchSell/INVALID_SUBCALL");
            }
            state.from = state.to;
        }
    }

    function multiplexBatchSellTokenForToken(
        IERC20 inputToken,
        IERC20 outputToken,
        BatchSellSubcall[] calldata calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) public override returns (uint256 boughtAmount) {
        return
            _multiplexBatchSell(
                BatchSellParams({
                    inputToken: inputToken,
                    outputToken: outputToken,
                    sellAmount: sellAmount,
                    calls: calls,
                    useSelfBalance: false,
                    recipient: msg.sender
                }),
                minBuyAmount
            );
    }

    function _multiplexBatchSell(
        BatchSellParams memory params,
        uint256 minBuyAmount
    ) private returns (uint256 boughtAmount) {
        uint256 balanceBefore = params.outputToken.balanceOf(params.recipient);
        BatchSellState memory state = _executeBatchSell(params);
        uint256 balanceDelta = params
            .outputToken
            .balanceOf(params.recipient)
            .sub(balanceBefore);
        boughtAmount = Math.min(balanceDelta, state.boughtAmount);

        require(
            boughtAmount >= minBuyAmount,
            "MultiplexFeature::_multiplexBatchSell/UNDERBOUGHT"
        );
    }

    function multiplexMultiHopSellTokenForToken(
        address[] calldata tokens,
        MultiHopSellSubcall[] calldata calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) public override returns (uint256 boughtAmount) {
        return
            _multiplexMultiHopSell(
                MultiHopSellParams({
                    tokens: tokens,
                    sellAmount: sellAmount,
                    calls: calls,
                    useSelfBalance: false,
                    recipient: msg.sender
                }),
                minBuyAmount
            );
    }

    function _multiplexMultiHopSell(
        MultiHopSellParams memory params,
        uint256 minBuyAmount
    ) public returns (uint256 boughtAmount) {
        require(
            params.tokens.length == params.calls.length + 1,
            "MultiplexFeature::_multiplexMultiHopSell/MISMATCHED_ARRAY_LENGTHS"
        );
        IERC20 outputToken = IERC20(params.tokens[params.tokens.length - 1]);
        uint256 balanceBefore = outputToken.balanceOf(params.recipient);
        MultiHopSellState memory state = _executeMultiHopSell(params);
        uint256 balanceDelta = outputToken.balanceOf(params.recipient).sub(
            balanceBefore
        );
        boughtAmount = Math.min(balanceDelta, state.outputTokenAmount);

        require(
            boughtAmount >= minBuyAmount,
            "MultiplexFeature::_multiplexMultiHopSell/UNDERBOUGHT"
        );
    }

    function _nestedBatchSell(
        MultiHopSellState memory state,
        MultiHopSellParams memory params,
        bytes memory data
    ) private {
        BatchSellParams memory batchSellParams;
        batchSellParams.calls = abi.decode(data, (BatchSellSubcall[]));
        batchSellParams.inputToken = IERC20(params.tokens[state.hopIndex]);
        batchSellParams.outputToken = IERC20(params.tokens[state.hopIndex + 1]);
        // the output token from previous sell is input token for current batch sell
        batchSellParams.sellAmount = state.outputTokenAmount;
        batchSellParams.recipient = state.to;
        batchSellParams.useSelfBalance =
            state.hopIndex > 0 ||
            params.useSelfBalance;

        state.outputTokenAmount = _executeBatchSell(batchSellParams)
            .boughtAmount;
    }

    function _nestedMultiHopSell(
        BatchSellState memory state,
        BatchSellParams memory params,
        bytes memory data,
        uint256 sellAmount
    ) private {
        MultiHopSellParams memory multiHopSellParams;
        (multiHopSellParams.tokens, multiHopSellParams.calls) = abi.decode(
            data,
            (address[], MultiHopSellSubcall[])
        );
        multiHopSellParams.sellAmount = sellAmount;
        multiHopSellParams.recipient = params.recipient;
        multiHopSellParams.useSelfBalance = params.useSelfBalance;

        uint256 outputTokenAmount = _executeMultiHopSell(multiHopSellParams)
            .outputTokenAmount;
        state.soldAmount = state.soldAmount.add(sellAmount);
        state.boughtAmount = state.boughtAmount.add(outputTokenAmount);
    }

    // This function computes the "target" address of hop index `i` within
    // a multi-hop sell.
    // If `i == 0`, the target is the address which should hold the input
    // tokens prior to executing `calls[0]`. Otherwise, it is the address
    // that should receive `tokens[i]` upon executing `calls[i-1]`.
    function computeHopTarget(MultiHopSellParams memory params, uint256 i)
        private
        view
        returns (address target)
    {
        if (i == params.calls.length) {
            // The last call should send the output tokens to the
            // multi-hop sell recipient.
            target = params.recipient;
        } else {
            if (i == 0) {
                // the input token are held by msg.sender for the first time
                target = msg.sender;
            } else {
                // the intermediate token only held by self
                target = address(this);
            }
        }
    }

    // If `rawAmount` encodes a proportion of `totalSellAmount`, this function
    // converts it to an absolute quantity. Caps the normalized amount to
    // the remaining sell amount (`totalSellAmount - soldAmount`).
    function _normalizeSellAmount(
        uint256 rawAmount,
        uint256 totalSellAmount,
        uint256 soldAmount
    ) private pure returns (uint256 normalized) {
        if ((rawAmount & HIGH_BIT) == HIGH_BIT) {
            // If the high bit of `rawAmount` is set then the lower 255 bits
            // specify a fraction of `totalSellAmount`.
            return
                Math.min(
                    (totalSellAmount *
                        Math.min(rawAmount & LOWER_255_BITS, 1e18)) / 1e18,
                    totalSellAmount.sub(soldAmount)
                );
        } else {
            return Math.min(rawAmount, totalSellAmount.sub(soldAmount));
        }
    }
}
