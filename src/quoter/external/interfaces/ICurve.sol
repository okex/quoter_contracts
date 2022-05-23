// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICurve {
    // solhint-disable-next-line
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) external;

    // solhint-disable-next-line
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 sellAmount
    ) external returns (uint256 dy);

    // solhint-disable-next-line
    function get_dx_underlying(
        int128 i,
        int128 j,
        uint256 buyAmount
    ) external returns (uint256 dx);
}
