// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDODOZoo {
    function getDODO(address baseToken, address quoteToken)
        external
        view
        returns (address);
}

interface IDODO {
    function querySellBaseToken(uint256 amount) external view returns (uint256);

    // solhint-disable-next-line
    function _TRADE_ALLOWED_() external view returns (bool);
}

interface IDODOHelper {
    function querySellQuoteToken(address pool, uint256 amount)
        external
        view
        returns (uint256);
}
