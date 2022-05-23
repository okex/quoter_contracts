// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./MultiplexFeature.sol";
import "./TransformERC20Feature.sol";
import "./QuoteERC20Feature.sol";

contract Swapper is MultiplexFeature, TransformERC20Feature {}
