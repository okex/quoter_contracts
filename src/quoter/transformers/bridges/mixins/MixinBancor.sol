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
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../IBridgeAdapter.sol";
import "../LibERC20Token.sol";
import "../IWETH.sol";

interface IBancorNetwork {
    function convertByPath(
        IERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _beneficiary,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) external payable returns (uint256);
}

contract MixinBancor {
    using LibERC20Token for IERC20;

    /// @dev Bancor ETH pseudo-address.
    IERC20 public constant BANCOR_ETH_ADDRESS =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IWETH private immutable WETH;

    constructor(IWETH weth) {
        WETH = weth;
    }

    function _tradeBancor(
        IERC20 buyToken,
        uint256 sellAmount,
        bytes memory bridgeData
    ) internal returns (uint256 boughtAmount) {
        // Decode the bridge data.
        IBancorNetwork bancorNetworkAddress;
        IERC20[] memory path;
        {
            address[] memory _path;
            (bancorNetworkAddress, _path) = abi.decode(
                bridgeData,
                (IBancorNetwork, address[])
            );
            // To get around `abi.decode()` not supporting interface array types.
            assembly {
                path := _path
            }
        }

        require(
            path.length >= 2,
            "MixinBancor/PATH_LENGTH_MUST_BE_AT_LEAST_TWO"
        );
        require(
            path[path.length - 1] == buyToken ||
                (path[path.length - 1] == BANCOR_ETH_ADDRESS &&
                    address(buyToken) == address(WETH)),
            "MixinBancor/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN"
        );

        uint256 payableAmount = 0;
        // If it's ETH in the path then withdraw from WETH
        // The Bancor path will have ETH as the 0xeee address
        // Bancor expects to be paid in ETH not WETH
        if (path[0] == BANCOR_ETH_ADDRESS) {
            WETH.withdraw(sellAmount);
            payableAmount = sellAmount;
        } else {
            // Grant an allowance to the Bancor Network.
            LibERC20Token.approveIfBelow(
                path[0],
                address(bancorNetworkAddress),
                sellAmount
            );
        }

        // Convert the tokens
        boughtAmount = bancorNetworkAddress.convertByPath{value: payableAmount}(
            path, // path originating with source token and terminating in destination token
            sellAmount, // amount of source token to trade
            1, // minimum amount of destination token expected to receive
            address(this), // beneficiary
            address(0), // affiliateAccount; no fee paid
            0 // affiliateFee; no fee paid
        );
        if (path[path.length - 1] == BANCOR_ETH_ADDRESS) {
            WETH.deposit{value: boughtAmount}();
        }

        return boughtAmount;
    }
}
