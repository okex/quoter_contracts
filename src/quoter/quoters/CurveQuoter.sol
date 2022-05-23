// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../external/interfaces/ICurve.sol";

contract CurveQuoter {
    struct QuoteFromCurveParams {
        address poolAddress;
        bytes4 sellQuoteFunctionSelector;
        bytes4 buyQuoteFunctionSelector;
        uint256 fromTokenIdx;
        uint256 toTokenIdx;
    }

    function quoteSellFromCurve(
        uint256 takerTokenAmount,
        bytes calldata wrappedCallData
    ) public view returns (uint256 makerTokenAmount) {
        QuoteFromCurveParams memory params = abi.decode(
            wrappedCallData,
            (QuoteFromCurveParams)
        );
        (bool didSucceed, bytes memory resultData) = params
            .poolAddress
            .staticcall(
                abi.encodeWithSelector(
                    params.sellQuoteFunctionSelector,
                    params.fromTokenIdx,
                    params.toTokenIdx,
                    takerTokenAmount
                )
            );
        uint256 buyAmount = 0;
        if (didSucceed) {
            buyAmount = abi.decode(resultData, (uint256));
        }

        makerTokenAmount = buyAmount;
    }

    function quoteBuyFromCurve(
        uint256 makerTokenAmount,
        bytes calldata wrappedCallData
    ) public view returns (uint256 takerTokenAmount) {
        QuoteFromCurveParams memory params = abi.decode(
            wrappedCallData,
            (QuoteFromCurveParams)
        );
        (bool didSucceed, bytes memory resultData) = params
            .poolAddress
            .staticcall(
                abi.encodeWithSelector(
                    params.buyQuoteFunctionSelector,
                    params.fromTokenIdx,
                    params.toTokenIdx,
                    makerTokenAmount
                )
            );
        uint256 buyAmount = 0;
        if (didSucceed) {
            buyAmount = abi.decode(resultData, (uint256));
        }

        takerTokenAmount = buyAmount;
    }
}
