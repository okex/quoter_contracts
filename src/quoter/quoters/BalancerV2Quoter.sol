// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../external/interfaces/IBalancerV2.sol";

contract BalancerV2Quoter {
    struct QuoteFromBalancerV2Params {
        bytes32 poolId;
        address vault;
        address takerToken;
        address makerToken;
    }

    function quoteSellFromBalancerV2(
        uint256 takerTokenAmount,
        bytes calldata wrappedCallData
    ) public returns (uint256 makerTokenAmount) {
        QuoteFromBalancerV2Params memory params = abi.decode(
            wrappedCallData,
            (QuoteFromBalancerV2Params)
        );
        IBalancerV2Vault vault = IBalancerV2Vault(params.vault);
        IBalancerV2Vault.FundManagement memory swapFunds = _createSwapFunds();
        IBalancerV2Vault.BatchSwapStep[] memory swapSteps = _createSwapStep(
            params.poolId,
            takerTokenAmount
        );
        IAsset[] memory swapAssets = new IAsset[](2);
        swapAssets[0] = IAsset(params.takerToken);
        swapAssets[1] = IAsset(params.makerToken);
        try
            vault.queryBatchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                swapSteps,
                swapAssets,
                swapFunds
            )
        returns (int256[] memory amounts) {
            // output is negative
            makerTokenAmount = uint256(amounts[1] * -1);
        } catch (bytes memory) {}
    }

    function quoteBuyFromBalancerV2(
        uint256 makerTokenAmount,
        bytes calldata wrappedCallData
    ) public returns (uint256 takerTokenAmount) {
        QuoteFromBalancerV2Params memory params = abi.decode(
            wrappedCallData,
            (QuoteFromBalancerV2Params)
        );
        IBalancerV2Vault vault = IBalancerV2Vault(params.vault);
        IBalancerV2Vault.FundManagement memory swapFunds = _createSwapFunds();
        IBalancerV2Vault.BatchSwapStep[] memory swapSteps = _createSwapStep(
            params.poolId,
            makerTokenAmount
        );
        IAsset[] memory swapAssets = new IAsset[](2);
        swapAssets[0] = IAsset(params.takerToken);
        swapAssets[1] = IAsset(params.makerToken);
        try
            vault.queryBatchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_OUT,
                swapSteps,
                swapAssets,
                swapFunds
            )
        returns (int256[] memory amounts) {
            int256 amountIntoPool = amounts[0];
            takerTokenAmount = uint256(amountIntoPool);
        } catch (bytes memory) {}
    }

    function _createSwapStep(bytes32 poolId, uint256 amount)
        private
        pure
        returns (IBalancerV2Vault.BatchSwapStep[] memory)
    {
        IBalancerV2Vault.BatchSwapStep[]
            memory swapSteps = new IBalancerV2Vault.BatchSwapStep[](1);
        swapSteps[0] = IBalancerV2Vault.BatchSwapStep({
            poolId: poolId,
            assetInIndex: 0,
            assetOutIndex: 1,
            amount: amount,
            userData: ""
        });

        return swapSteps;
    }

    function _createSwapFunds()
        private
        view
        returns (IBalancerV2Vault.FundManagement memory)
    {
        return
            IBalancerV2Vault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            });
    }
}
