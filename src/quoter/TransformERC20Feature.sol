// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/ITransformERC20Feature.sol";
import "./transformers/IERC20Transformer.sol";
import "./libs/LibERC20Transformer.sol";
import "./libs/LibTransformERC20RichErrors.sol";
import "./libs/LibRichErrors.sol";

contract TransformERC20Feature is ITransformERC20Feature {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using LibRichErrors for bytes;

    struct TransformERC20PrivateState {
        uint256 recipientOutputTokenBalanceBefore;
        uint256 recipientOutputTokenBalanceAfter;
    }

    modifier onlySelf() virtual {
        if (msg.sender != address(this)) {
            revert("ONLYSELF");
        }
        _;
    }

    function transformERC20(
        IERC20 inputToken,
        IERC20 outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] memory transformations
    ) public payable override returns (uint256 outputTokenAmount) {
        return
            _transformERC20Private(
                TransformERC20Args({
                    taker: payable(msg.sender),
                    inputToken: inputToken,
                    outputToken: outputToken,
                    inputTokenAmount: inputTokenAmount,
                    useSelfBalance: false,
                    transformations: transformations,
                    minOutputTokenAmount: minOutputTokenAmount,
                    recipient: payable(msg.sender)
                })
            );
    }

    function _transformERC20(TransformERC20Args memory args)
        public
        payable
        virtual
        override
        onlySelf
        returns (uint256 outputTokenAmount)
    {
        return _transformERC20Private(args);
    }

    function _transformERC20Private(TransformERC20Args memory args)
        private
        returns (uint256 outputTokenAmount)
    {
        TransformERC20PrivateState memory state;

        // Remember the initial output token balance of the recipient.
        state.recipientOutputTokenBalanceBefore = LibERC20Transformer
            .getTokenBalanceOf(args.outputToken, args.recipient);

        // Pull input tokens from the taker to the wallet and transfer attached ETH.
        if (!args.useSelfBalance) {
            _transferInputTokensAndAttachedEth(args, address(this));
        }
        {
            for (uint256 i = 0; i < args.transformations.length; ++i) {
                _executeTransformation(
                    args.transformations[i],
                    args.inputTokenAmount
                );
            }

            if (address(this) != args.recipient) {
                // Transfer output tokens from this to recipient
                _executeOutputTokenTransfer(args.outputToken, args.recipient);
            }
        }

        // Compute how much output token has been transferred to the recipient.
        state.recipientOutputTokenBalanceAfter = LibERC20Transformer
            .getTokenBalanceOf(args.outputToken, args.recipient);
        require(
            state.recipientOutputTokenBalanceAfter >=
                state.recipientOutputTokenBalanceBefore,
            "output token is less after tradeing"
        );
        outputTokenAmount = state.recipientOutputTokenBalanceAfter.sub(
            state.recipientOutputTokenBalanceBefore
        );
        // Ensure enough output token has been sent to the taker.
        require(
            outputTokenAmount >= args.minOutputTokenAmount,
            "check minOutputToken failed"
        );
    }

    function _executeTransformation(
        Transformation memory transformation,
        uint256 tokenLimits
    ) private {
        address transformer = transformation.transformer;
        (bool success, bytes memory resultData) = transformer.delegatecall(
            abi.encodeWithSelector(
                IERC20Transformer.transform.selector,
                IERC20Transformer.TransformContext({
                    data: transformation.data,
                    tokenLimits: tokenLimits,
                    recipient: payable(msg.sender)
                })
            )
        );

        if (!success) {
            LibTransformERC20RichErrors
                .TransformerFailedError(
                    transformer,
                    transformation.data,
                    resultData
                )
                .rrevert();
        }
    }

    /// @dev Transfer input tokens and any attached ETH to `to`
    /// @param args A `TransformERC20Args` struct.
    /// @param to The recipient of tokens and ETH.
    function _transferInputTokensAndAttachedEth(
        TransformERC20Args memory args,
        address to
    ) private {
        if (
            LibERC20Transformer.isTokenETH(args.inputToken) &&
            msg.value < args.inputTokenAmount
        ) {
            revert("InsufficientEthAttachedError");
        }

        // Transfer input tokens.
        if (!LibERC20Transformer.isTokenETH(args.inputToken)) {
            // Pull ERC20 tokens from taker.
            args.inputToken.safeTransferFrom(
                args.taker,
                to,
                args.inputTokenAmount
            );
        }
    }

    function _executeOutputTokenTransfer(
        IERC20 outputToken,
        address payable recipient
    ) private returns (uint256 transferAmount) {
        transferAmount = LibERC20Transformer.getTokenBalanceOf(
            outputToken,
            address(this)
        );
        LibERC20Transformer.transformerTransfer(
            outputToken,
            recipient,
            transferAmount
        );
    }
}
