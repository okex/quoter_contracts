// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../LibERC20Token.sol";

interface IBalancerPool {
    /// @dev Sell `tokenAmountIn` of `tokenIn` and receive `tokenOut`.
    /// @param tokenIn The token being sold
    /// @param tokenAmountIn The amount of `tokenIn` to sell.
    /// @param tokenOut The token being bought.
    /// @param minAmountOut The minimum amount of `tokenOut` to buy.
    /// @param maxPrice The maximum value for `spotPriceAfter`.
    /// @return tokenAmountOut The amount of `tokenOut` bought.
    /// @return spotPriceAfter The new marginal spot price of the given
    ///         token pair for this pool.
    function swapExactAmountIn(
        IERC20 tokenIn,
        uint256 tokenAmountIn,
        IERC20 tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);
}

contract MixinBalancer {
    using LibERC20Token for IERC20;

    function _tradeBalancer(
        IERC20 sellToken,
        IERC20 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        // Decode the bridge data.
        IBalancerPool pool = abi.decode(bridgeData, (IBalancerPool));
        sellToken.approveIfBelow(address(pool), sellAmount);
        // Sell all of this contract's `sellToken` token balance.
        (boughtAmount, ) = pool.swapExactAmountIn(
            sellToken, // tokenIn
            sellAmount, // tokenAmountIn
            buyToken, // tokenOut
            1, // minAmountOut
            type(uint256).max // maxPrice
        );
        return boughtAmount;
    }
}
