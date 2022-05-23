// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBridgeAdapter {
    struct BridgeOrder {
        // Upper 16 bytes: uint128 protocol ID (right-aligned)
        // Lower 16 bytes: ASCII source name (left-aligned)
        bytes32 source;
        uint256 takerTokenAmount;
        uint256 makerTokenAmount;
        bytes bridgeData;
    }

    /// @dev Emitted when tokens are swapped with an external source.
    /// @param source A unique ID for the source, where the upper 16 bytes
    ///        encodes the (right-aligned) uint128 protocol ID and the
    ///        lower 16 bytes encodes an ASCII source name.
    /// @param inputToken The token the bridge is converting from.
    /// @param outputToken The token the bridge is converting to.
    /// @param inputTokenAmount Amount of input token sold.
    /// @param outputTokenAmount Amount of output token bought.
    event BridgeFill(
        bytes32 source,
        IERC20 inputToken,
        IERC20 outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount
    );

    function trade(
        BridgeOrder calldata order,
        IERC20 sellToken,
        IERC20 buyToken,
        uint256 sellAmount
    ) external returns (uint256 boughtAmount);
}
