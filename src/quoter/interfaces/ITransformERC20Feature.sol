// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITransformERC20Feature {
    struct Transformation {
        address transformer;
        bytes data;
    }

    struct TransformERC20Args {
        IERC20 inputToken;
        IERC20 outputToken;
        uint256 inputTokenAmount;
        uint256 minOutputTokenAmount;
        bool useSelfBalance;
        Transformation[] transformations;
        address payable recipient;
        address payable taker;
    }

    function transformERC20(
        IERC20 inputToken,
        IERC20 outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] memory transformations
    ) external payable returns (uint256 outputTokenAmount);

    function _transformERC20(TransformERC20Args memory args)
        external
        payable
        returns (uint256 outputTokenAmount);
}
