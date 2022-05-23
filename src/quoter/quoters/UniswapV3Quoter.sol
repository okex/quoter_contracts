// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../external/interfaces/IUniswapV3.sol";

contract UniswapV3Quoter {
    struct QuoteFromUniswapV3Params {
        IUniswapV3Quoter quoter;
        IERC20[] path;
        uint24[] fees;
    }

    function quoteSellFromUniswapV3(
        uint256 takerTokenAmount,
        bytes calldata wrappedCallData
    ) public returns (uint256 makerTokenAmount) {
        QuoteFromUniswapV3Params memory params;
        params = abi.decode(wrappedCallData, (QuoteFromUniswapV3Params));
        bytes memory uniswapPath = _toUniswapPath(params.path, params.fees);
        try
            params.quoter.quoteExactInput(uniswapPath, takerTokenAmount)
        returns (uint256 buyAmount) {
            makerTokenAmount = buyAmount;
        } catch {}
    }

    function quoteBuyFromUniswapV3(
        uint256 makerTokenAmount,
        bytes calldata wrappedCallData
    ) public returns (uint256 takerTokenAmount) {
        QuoteFromUniswapV3Params memory params;
        params = abi.decode(wrappedCallData, (QuoteFromUniswapV3Params));
        bytes memory uniswapPath = _toUniswapPath(params.path, params.fees);
        try
            params.quoter.quoteExactOutput(uniswapPath, makerTokenAmount)
        returns (uint256 buyAmount) {
            takerTokenAmount = buyAmount;
        } catch {}
    }

    function _toUniswapPath(IERC20[] memory tokenPath, uint24[] memory poolFees)
        private
        pure
        returns (bytes memory uniswapPath)
    {
        require(
            tokenPath.length >= 2 && tokenPath.length == poolFees.length + 1,
            "UniswapV3Sampler/invalid path lengths"
        );
        // Uniswap paths are tightly packed as:
        // [token0, token0token1PairFee, token1, token1Token2PairFee, token2, ...]
        uniswapPath = new bytes(tokenPath.length * 20 + poolFees.length * 3);
        uint256 o;
        assembly {
            o := add(uniswapPath, 32)
        }
        for (uint256 i = 0; i < tokenPath.length; ++i) {
            if (i > 0) {
                uint24 poolFee = poolFees[i - 1];
                assembly {
                    mstore(o, shl(232, poolFee))
                    o := add(o, 3)
                }
            }
            IERC20 token = tokenPath[i];
            assembly {
                mstore(o, shl(96, token))
                o := add(o, 20)
            }
        }
    }

    function isValidPool(IUniswapV3Pool pool)
        public
        view
        returns (bool isValid)
    {
        // code exist in pool
        {
            uint256 codeSize;
            assembly {
                codeSize := extcodesize(pool)
            }
            if (codeSize == 0) {
                return false;
            }
        }

        if (pool.token0().balanceOf(address(pool)) == 0) {
            return false;
        }

        if (pool.token1().balanceOf(address(pool)) == 0) {
            return false;
        }
        return true;
    }

    function isValidFee(
        IUniswapV3Quoter quoter,
        IERC20 token0,
        IERC20 token1,
        uint24 fee
    ) public view returns (bool) {
        IUniswapV3Pool pool = quoter.factory().getPool(token0, token1, fee);
        return isValidPool(pool);
    }
}
