// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./quoters/CurveQuoter.sol";
import "./quoters/UniswapV2Quoter.sol";
import "./quoters/UniswapV3Quoter.sol";
import "./quoters/DODOV2Quoter.sol";
import "./quoters/BalancerV2Quoter.sol";
import "./quoters/DODOQuoter.sol";
import "./interfaces/IQuoteERC20Feature.sol";

contract QuoteERC20Feature is
    IQuoteERC20Feature,
    CurveQuoter,
    UniswapV2Quoter,
    UniswapV3Quoter,
    DODOV2Quoter,
    DODOQuoter,
    BalancerV2Quoter
{
    function _quoteERC20(QuoteERC20Args calldata args)
        public
        override
        returns (uint256 outputTokenAmount)
    {
        bytes memory callData = abi.encodeWithSelector(
            args.quoteFunctionSelector,
            args.inputTokenAmount,
            args.wrappedCallData
        );
        (bool success, bytes memory resultData) = address(this).call(callData);
        if (!success) {
            revert("BatchSellQuoteFailedError");
        }
        outputTokenAmount = abi.decode(resultData, (uint256));
    }
}
