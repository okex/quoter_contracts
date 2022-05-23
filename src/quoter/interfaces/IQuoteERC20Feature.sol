// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IQuoteERC20Feature {
    struct QuoteERC20Args {
        uint256 inputTokenAmount;
        bytes4 quoteFunctionSelector;
        bytes wrappedCallData;
    }

    function _quoteERC20(QuoteERC20Args calldata args)
        external
        returns (uint256 outputTokenAmount);
}
