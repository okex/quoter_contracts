// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV3Pool {
    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function fee() external view returns (uint24);
}

interface IUniswapV3Factory {
    function getPool(
        IERC20 tokenA,
        IERC20 tokenB,
        uint24 fee
    ) external view returns (IUniswapV3Pool pool);
}

interface IUniswapV3Quoter {
    function factory() external view returns (IUniswapV3Factory);

    function quoteExactInput(bytes memory path, uint256 amountIn)
        external
        returns (uint256 amountOut);

    function quoteExactOutput(bytes memory path, uint256 amountOut)
        external
        returns (uint256 amountIn);
}
