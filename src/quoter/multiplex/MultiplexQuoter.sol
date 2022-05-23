// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IMultiplexFeature.sol";
import "../interfaces/IQuoteERC20Feature.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract MultiplexQuoter {
    using SafeMath for uint256;

    function _batchSellQuote(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        IQuoteERC20Feature.QuoteERC20Args memory args;
        (args.quoteFunctionSelector, args.wrappedCallData) = abi.decode(
            wrappedCallData,
            (bytes4, bytes)
        );
        params;
        args.inputTokenAmount = sellAmount;
        try IQuoteERC20Feature(address(this))._quoteERC20(args) returns (
            uint256 outputTokenAmount
        ) {
            state.soldAmount = state.soldAmount.add(sellAmount);
            state.boughtAmount = state.boughtAmount.add(outputTokenAmount);
        } catch {}
    }
}
