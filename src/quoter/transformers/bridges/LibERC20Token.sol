// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LibERC20Token {
    using SafeERC20 for IERC20;

    /// @dev Calls `IERC20Token(token).approve()` and sets the allowance to the
    ///      maximum if the current approval is not already >= an amount.
    ///      Reverts if `false` is returned or if the return
    ///      data length is nonzero and not 32 bytes.
    /// @param token The address of the token contract.
    /// @param spender The address that receives an allowance.
    /// @param amount The minimum allowance needed.
    function approveIfBelow(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (IERC20(token).allowance(address(this), spender) < amount) {
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }
}
