// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMultiplexFeature {
    enum MultiplexSubcall {
        Invalid,
        TransformERC20,
        BatchSell,
        MultiHopSell,
        Quoter
    }

    struct BatchSellParams {
        IERC20 inputToken;
        IERC20 outputToken;
        bool useSelfBalance;
        uint256 sellAmount;
        BatchSellSubcall[] calls;
        address recipient;
    }

    struct BatchSellSubcall {
        MultiplexSubcall id;
        uint256 sellAmount;
        bytes data;
    }

    struct BatchSellState {
        uint256 soldAmount;
        uint256 boughtAmount;
    }

    struct MultiHopSellParams {
        address[] tokens;
        uint256 sellAmount;
        MultiHopSellSubcall[] calls;
        address recipient;
        bool useSelfBalance;
    }

    struct MultiHopSellSubcall {
        MultiplexSubcall id;
        bytes data;
    }

    struct MultiHopSellState {
        uint256 outputTokenAmount;
        address from;
        address to;
        uint256 hopIndex;
    }

    function multiplexBatchSellTokenForToken(
        IERC20 inputToken,
        IERC20 outputToken,
        BatchSellSubcall[] calldata calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) external returns (uint256 boughtAmount);

    function multiplexMultiHopSellTokenForToken(
        address[] calldata tokens,
        MultiHopSellSubcall[] calldata calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) external returns (uint256 boughtAmount);
}
