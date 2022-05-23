// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../external/interfaces/IUniswapV2Route01.sol";

contract UniswapV2Quoter {
    struct QuoteFromUniswapV2Params {
        address router;
        address[] path;
    }

    function quoteSellFromUniswapV2(
        uint256 takerTokenAmount,
        bytes calldata wrappedCallData
    ) public view returns (uint256 makerTokenAmount) {
        QuoteFromUniswapV2Params memory params;
        params = abi.decode(wrappedCallData, (QuoteFromUniswapV2Params));
        try
            IUniswapV2Route01(params.router).getAmountsOut(
                takerTokenAmount,
                params.path
            )
        returns (uint256[] memory amounts) {
            makerTokenAmount = amounts[params.path.length - 1];
        } catch (bytes memory) {}
    }

    function quoteBuyFromUniswapV2(
        uint256 makerTokenAmount,
        bytes calldata wrappedCallData
    ) public view returns (uint256 takerTokenAmount) {
        QuoteFromUniswapV2Params memory params;
        params = abi.decode(wrappedCallData, (QuoteFromUniswapV2Params));
        try
            IUniswapV2Route01(params.router).getAmountsIn(
                makerTokenAmount,
                params.path
            )
        returns (uint256[] memory amounts) {
            takerTokenAmount = amounts[params.path.length - 1];
        } catch (bytes memory) {}
    }
}
