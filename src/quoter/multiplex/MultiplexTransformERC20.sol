// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IMultiplexFeature.sol";
import "../interfaces/ITransformERC20Feature.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract MultiplexTransformERC20 {
    using SafeMath for uint256;

    function _batchSellTransformERC20(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        ITransformERC20Feature.TransformERC20Args memory args;
        args.taker = payable(msg.sender);
        args.recipient = payable(params.recipient);
        args.inputToken = params.inputToken;
        args.outputToken = params.outputToken;
        args.useSelfBalance = params.useSelfBalance;
        args.inputTokenAmount = sellAmount;
        args.minOutputTokenAmount = 0;
        args.transformations = abi.decode(
            wrappedCallData,
            (ITransformERC20Feature.Transformation[])
        );

        // try
        uint256 outputTokenAmount = ITransformERC20Feature(address(this))
            ._transformERC20(args);
        // returns (uint256 outputTokenAmount) {
        state.soldAmount = state.soldAmount.add(sellAmount);
        state.boughtAmount = state.boughtAmount.add(outputTokenAmount);
        // } catch {}
    }
}
