// SPDX-License-Identifier: Apache-2.0

/*

  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../LibERC20Token.sol";
import "../IBridgeAdapter.sol";

interface IUniswapV3Router {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams memory params)
        external
        payable
        returns (uint256 amountOut);
}

contract MixinUniswapV3 {
    using LibERC20Token for IERC20;

    struct QuoteFromUniswapV3Params {
        IUniswapV3Router router;
        IERC20[] path;
        uint24[] fees;
    }

    function _tradeUniswapV3(
        IERC20 sellToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        QuoteFromUniswapV3Params memory params = abi.decode(
            bridgeData,
            (QuoteFromUniswapV3Params)
        );
        bytes memory path = _toUniswapPath(params.path, params.fees);

        // Grant the Uniswap router an allowance to sell the sell token.
        sellToken.approveIfBelow(address(params.router), sellAmount);

        boughtAmount = params.router.exactInput(
            IUniswapV3Router.ExactInputParams({
                path: path,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: sellAmount,
                amountOutMinimum: 1
            })
        );
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
}
