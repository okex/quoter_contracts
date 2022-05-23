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

library BridgeProtocols {
    // A incrementally increasing, append-only list of protocol IDs.
    // We don't use an enum so solidity doesn't throw when we pass in a
    // new protocol ID that hasn't been rolled up yet.
    uint128 internal constant UNKNOWN = 0;
    uint128 internal constant CURVE = 1;
    uint128 internal constant UNISWAPV2 = 2;
    uint128 internal constant BALANCER = 3;
    uint128 internal constant KYBER = 4;
    uint128 internal constant DODO = 5;
    uint128 internal constant DODOV2 = 6;
    uint128 internal constant BANCOR = 7;
    uint128 internal constant MAKERPSM = 8;
    uint128 internal constant BALANCERV2 = 9;
    uint128 internal constant UNISWAPV3 = 10;
    uint128 internal constant KYBERDMM = 11;
    uint128 internal constant CURVEV2 = 12;
}
