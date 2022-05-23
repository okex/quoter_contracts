// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IBalancerV2Vault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] calldata swaps,
        IAsset[] calldata assets,
        FundManagement calldata funds
    ) external returns (int256[] memory assetDeltas);
}

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}
