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
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../LibERC20Token.sol";
import "../IBridgeAdapter.sol";

interface IDODOV2 {
    function sellBase(address recipient) external returns (uint256);

    function sellQuote(address recipient) external returns (uint256);
}

contract MixinDodoV2 {
    using LibERC20Token for IERC20;
    using SafeERC20 for IERC20;

    function _tradeDodoV2(
        IERC20 sellToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        (IDODOV2 pool, bool isSellBase) = abi.decode(
            bridgeData,
            (IDODOV2, bool)
        );

        // Transfer the tokens into the pool
        sellToken.safeTransfer(address(pool), sellAmount);

        boughtAmount = isSellBase
            ? pool.sellBase(address(this))
            : pool.sellQuote(address(this));
    }
}
