// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../external/interfaces/IDODO.sol";

contract DODOQuoter {
    struct QuoteFromDODOParams {
        address registry;
        address helper;
        address takerToken;
        address makerToken;
    }

    function quoteSellFromDODO(
        uint256 takerTokenAmount,
        bytes calldata wrappedCallData
    )
        public
        view
        returns (
            uint256 makerTokenAmount,
            address pool,
            bool sellBase
        )
    {
        QuoteFromDODOParams memory params;
        params = abi.decode(wrappedCallData, (QuoteFromDODOParams));
        pool = IDODOZoo(params.registry).getDODO(
            params.takerToken,
            params.makerToken
        );
        if (pool != address(0)) {
            sellBase = true;
        } else {
            pool = IDODOZoo(params.registry).getDODO(
                params.makerToken,
                params.takerToken
            );
            if (pool == address(0)) {
                return (makerTokenAmount, pool, sellBase);
            }
            sellBase = false;
        }

        if (!IDODO(pool)._TRADE_ALLOWED_()) {
            return (makerTokenAmount, pool, sellBase);
        }

        if (sellBase) {
            makerTokenAmount = IDODO(pool).querySellBaseToken(takerTokenAmount);
        } else {
            makerTokenAmount = IDODOHelper(params.helper).querySellQuoteToken(
                pool,
                takerTokenAmount
            );
        }
    }

    function quoteBuyFromDODO(
        uint256 makerTokenAmount,
        bytes calldata wrappedCallData
    )
        public
        pure
        returns (
            uint256 takerTokenAmount,
            address pool,
            bool sellBase
        )
    {
        QuoteFromDODOParams memory params;
        makerTokenAmount;
        params = abi.decode(wrappedCallData, (QuoteFromDODOParams));
        // TODO (approximatly calculation)
        takerTokenAmount;
        pool;
        sellBase;
    }
}
