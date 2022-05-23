// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDODOV2Registry {
    function getDODOPool(address baseToken, address quoteToken)
        external
        view
        returns (address[] memory machine);
}

interface IDODOV2Pool {
    function querySellQuote(address trader, uint256 payQuoteAmount)
        external
        view
        returns (uint256 receiveBaseAmount, uint256 mFee);

    function querySellBase(address trader, uint256 payBaseAmount)
        external
        view
        returns (uint256 receiveQuoteAmount, uint256 mFee);
}
