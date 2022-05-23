// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../external/interfaces/IDODOV2.sol";

contract DODOV2Quoter {
    struct QuoteFromDODOV2Params {
        address registry;
        uint256 offset;
        address takerToken;
        address makerToken;
    }

    function quoteSellFromDODOV2(
        uint256 takerTokenAmount,
        bytes calldata wrappedCallData
    )
        public
        view
        returns (
            uint256 makerTokenAmount,
            bool sellBase,
            address pool
        )
    {
        QuoteFromDODOV2Params memory params = abi.decode(
            wrappedCallData,
            (QuoteFromDODOV2Params)
        );
        (pool, sellBase) = _getNextDODOV2Pool(params);
        if (sellBase) {
            try
                IDODOV2Pool(pool).querySellBase(address(0), takerTokenAmount)
            returns (uint256 amount, uint256) {
                makerTokenAmount = amount;
            } catch {
                makerTokenAmount = 0;
            }
        } else {
            try
                IDODOV2Pool(pool).querySellQuote(address(0), takerTokenAmount)
            returns (uint256 amount, uint256) {
                makerTokenAmount = amount;
            } catch {
                makerTokenAmount = 0;
            }
        }
    }

    function quoteBuyFromDODOV2(
        uint256 makerTokenAmount,
        bytes calldata wrappedCallData
    ) public pure returns (uint256 takerTokenAmount) {
        makerTokenAmount;
        takerTokenAmount;
        QuoteFromDODOV2Params memory params = abi.decode(
            wrappedCallData,
            (QuoteFromDODOV2Params)
        );
        params;
    }

    function _getNextDODOV2Pool(QuoteFromDODOV2Params memory params)
        internal
        view
        returns (address machine, bool sellBase)
    {
        address[] memory machines = IDODOV2Registry(params.registry)
            .getDODOPool(params.takerToken, params.makerToken);
        sellBase = true;
        if (machines.length == 0) {
            machines = IDODOV2Registry(params.registry).getDODOPool(
                params.makerToken,
                params.takerToken
            );
            sellBase = false;
        }
        if (params.offset >= machines.length) {
            return (address(0), false);
        }
        machine = machines[params.offset];
    }
}
