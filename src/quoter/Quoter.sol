// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./MultiplexFeature.sol";
import "./TransformERC20Feature.sol";
import "./QuoteERC20Feature.sol";

contract Quoter is MultiplexFeature, QuoteERC20Feature {
    struct CallResults {
        bool success;
        bytes data;
    }

    function batchCall(bytes[] calldata callDatas)
        external
        returns (CallResults[] memory callResults)
    {
        callResults = new CallResults[](callDatas.length);

        for (uint256 i = 0; i < callDatas.length; ++i) {
            callResults[i].success = true;
            if (callDatas[i].length == 0) {
                continue;
            }
            (callResults[i].success, callResults[i].data) = address(this).call(
                callDatas[i]
            );
        }
    }
}
