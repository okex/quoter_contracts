// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";

import {Vm} from "forge-std/Vm.sol";

import { ERC20BridgeSampler } from "../sampler/ERC20BridgeSampler.sol";
import { IUniswapV3Quoter, IUniswapV3Pool } from "../sampler/UniswapV3Sampler.sol";
import { IKyberDmmRouter } from '../sampler/KyberDmmSampler.sol';

contract SamplerTest is DSTest, ERC20BridgeSampler {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
    }

    ////////////////////////////////////////////
    /// test curve pools
    function testCryptoRegistryPool() public {
        // bytes[] memory callDatas = new bytes[](2);
        uint256[] memory takerTokenAmounts = new uint256[](1);
        takerTokenAmounts[0] = 1000000000;
        address poolAddress = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46; // cryptopool
        address fromToken = WETH; // WETH
        address toToken = USDT; // USDT
        uint256[] memory makerTokenAmounts = sampleSellsFromCurve(
            poolAddress,
            fromToken,
            toToken,
            takerTokenAmounts
        );
        assertGt(makerTokenAmounts[0], 0);
    }

    function testPlainPool() public {
        uint256[] memory takerTokenAmounts = new uint256[](1);
        takerTokenAmounts[0] = 1000000000000000000000;
        address poolAddress = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7; // 3pool
        address fromToken = DAI; // DAI
        address toToken = USDT; // USDT
        uint256[] memory makerTokenAmounts = sampleSellsFromCurve(
            poolAddress,
            fromToken,
            toToken,
            takerTokenAmounts
        );
        assertGt(makerTokenAmounts[0], 0);
    }

    function testLendingPool() public {
        // bytes[] memory callDatas = new bytes[](2);
        uint256[] memory takerTokenAmounts = new uint256[](1);
        takerTokenAmounts[0] = 1000000000000000000000;
        address poolAddress = 0xDeBF20617708857ebe4F679508E7b7863a8A8EeE; // lending pool
        address fromToken = 0x028171bCA77440897B824Ca71D1c56caC55b68A3; // aDAI
        address toToken = 0xBcca60bB61934080951369a648Fb03DF4F96263C; // aUSDC
        uint256[] memory makerTokenAmounts = sampleSellsFromCurve(
            poolAddress,
            fromToken,
            toToken,
            takerTokenAmounts
        );
        assertGt(makerTokenAmounts[0], 0);

        makerTokenAmounts = sampleSellsFromCurve(
            poolAddress,
            DAI,// DAI
            USDC,// USDC
            takerTokenAmounts
        );
        assertGt(makerTokenAmounts[0], 0);
    }

    function testMetaPool() public {
        // bytes[] memory callDatas = new bytes[](2);
        uint256[] memory takerTokenAmounts = new uint256[](1);
        takerTokenAmounts[0] = 1000000000000000000000;
        address poolAddress = 0x4f062658EaAF2C1ccf8C8e36D6824CDf41167956; // metapool pool(gusd)
        // one is meta coin, the other is underlying coin
        address fromToken =  0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd; // gusd
        address toToken = USDC; // USDC
        uint256[] memory makerTokenAmounts = sampleSellsFromCurve(
            poolAddress,
            fromToken,
            toToken,
            takerTokenAmounts
        );
        assertGt(makerTokenAmounts[0], 0);

        // both of two are underlying coins
        makerTokenAmounts = sampleSellsFromCurve(
            poolAddress,
            DAI,// DAI
            USDC,// USDC
            takerTokenAmounts
        );
        assertGt(makerTokenAmounts[0], 0);


        // test pools that don't have base_pool function
        makerTokenAmounts = sampleSellsFromCurve(
            0xEcd5e75AFb02eFa118AF914515D6521aaBd189F1,// tusd pool
            0x0000000000085d4780B73119b644AE5ecd22b376,// TUSD
            DAI,
            takerTokenAmounts
        );
        assertGt(makerTokenAmounts[0], 0);

        // both of two are underlying coins
        makerTokenAmounts = sampleSellsFromCurve(
            0xEcd5e75AFb02eFa118AF914515D6521aaBd189F1,// tusd pool
            DAI,// DAI
            USDC,// USDC
            takerTokenAmounts
        );
        assertGt(makerTokenAmounts[0], 0);
    }

    function testYPool()public{
        uint256[] memory takerTokenAmounts = new uint256[](1);
        takerTokenAmounts[0] = 1000000000000000000000;
        // coins
        uint256[] memory makerTokenAmounts = sampleSellsFromCurve(
            0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51,// Y pool
            0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01,// yDAI
            0xd6aD7a6750A7593E092a9B218d66C0A814a3436e,// yUSDC
            takerTokenAmounts
        );
        assertGt(makerTokenAmounts[0], 0);

        // underlying coins
        makerTokenAmounts = sampleSellsFromCurve(
            0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51,// Y pool
            DAI,
            USDC,
            takerTokenAmounts
        );
        assertGt(makerTokenAmounts[0], 0);
    }

    function testCryptoFactoryPool()public{
        uint256[] memory takerTokenAmounts = new uint256[](1);
        takerTokenAmounts[0] = 1000000000000000000000;
        // coins
        uint256[] memory makerTokenAmounts = sampleSellsFromCurve(
            0x3211C6cBeF1429da3D0d58494938299C92Ad5860,//  crypto factory pool
            0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6,// stg
            USDC,
            takerTokenAmounts
        );
        assertGt(makerTokenAmounts[0], 0);
    }

    function testUniswapV2() public {
        uint256[] memory takerTokenAmounts = new uint256[](1);
        takerTokenAmounts[0] = 100000000000;
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        address[] memory path = new address[](2);
        path[0] = DAI;
        path[1] = USDC;
        uint256[] memory makerTokenAmounts = sampleSellsFromUniswapV2(router, path, takerTokenAmounts);
        assertGt(makerTokenAmounts[0], 0);
    }

    function testUniswapV3() public{
        uint256[] memory takerTokenAmounts = new uint256[](1);
        takerTokenAmounts[0] = 1000000000;
        address quoter = 0x61fFE014bA17989E743c5F6cB21bF9697530B21e;
        address pool = 0x3416cF6C708Da44DB2624D63ea0AAef7113527C6;
        uint256[] memory makerTokenAmounts = sampleSellsFromUniswapV3(UniswapV3SamplerOpts({quoter:IUniswapV3Quoter(quoter), pool: IUniswapV3Pool(pool)}), USDC,USDT, takerTokenAmounts);
        assertGt(makerTokenAmounts[0], 0);
    }

    function testBalancer()public{
        uint256[] memory takerTokenAmounts = new uint256[](1);
        takerTokenAmounts[0] = 1000000000;
        address poolAddress = 0x8a649274E4d777FFC6851F13d23A86BBFA2f2Fbf;
        address takerToken = WETH;
        address makerToken = USDC;
        uint256[] memory makerTokenAmounts =  sampleSellsFromBalancer(
        poolAddress,
        takerToken,
        makerToken,
        takerTokenAmounts
        );
        assertGt(makerTokenAmounts[0], 0);
    }

    function testBalancerV2()public{
        uint256[] memory takerTokenAmounts = new uint256[](1);
        takerTokenAmounts[0] = 1000000000;
        address pool = 0x06Df3b2bbB68adc8B0e302443692037ED9f91b42;
        address vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
        uint256[] memory makerTokenAmounts = sampleSellsFromBalancerV2(
            BalancerV2PoolInfo({pool: pool, vault: vault}),
            USDC,
            DAI,
            takerTokenAmounts
        );
        assertGt(makerTokenAmounts[0], 0);
    }

    function testDODO()public{
        uint256[] memory takerTokenAmounts = new uint256[](1);
        takerTokenAmounts[0] = 1000000000;
        bool sellBase = true;
        address helper = 0x533dA777aeDCE766CEAe696bf90f8541A4bA80Eb;
        address pool = 0xC9f93163c99695c6526b799EbcA2207Fdf7D61aD;
        uint256[] memory makerTokenAmounts = sampleSellsFromDODO(DODOSamplerOpts({
            pool: pool,
            sellBase: sellBase,
            helper: helper
        }),
        USDT,
        USDC,
        takerTokenAmounts);
        assertGt(makerTokenAmounts[0], 0);
    }

    function testDODOV2()public{
        uint256[] memory takerTokenAmounts = new uint256[](1);
        takerTokenAmounts[0] = 10000000000000000000;
        bool sellBase = true;
        address pool = 0x3058EF90929cb8180174D74C507176ccA6835D73;
        uint256[] memory makerTokenAmounts = sampleSellsFromDODOV2(DODOV2SamplerOpts({
            pool: pool,
            sellBase: sellBase
        }),
        DAI,
        USDT,
        takerTokenAmounts);
        assertGt(makerTokenAmounts[0], 0);
    }

    function testMakerPSM()public{
        uint256[] memory takerTokenAmounts = new uint256[](1);
        takerTokenAmounts[0] = 10000000000000000000;

        bytes32 ilkIdentifier = bytes32(abi.encodePacked("PSM-USDC-A"));

        uint256[] memory makerTokenAmounts = sampleSellsFromMakerPsm(
        MakerPsmInfo({
            psmAddress:0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A,
            ilkIdentifier: ilkIdentifier,
            gemTokenAddress: USDC
        }),
        DAI,
        USDC,
        takerTokenAmounts
        );
        assertGt(makerTokenAmounts[0], 0);
    }

    function testKyberDmm()public{
        uint256[] memory takerTokenAmounts = new uint256[](1);
        takerTokenAmounts[0] = 10000000000000000000;
        address pool = 0xD478953D5572f829f457A5052580cBEaee36c1Aa;
        address router = 0x1c87257F5e8609940Bc751a07BB085Bb7f8cDBE6;

        uint256[] memory makerTokenAmounts = sampleSellsFromKyberDmm(
            KyberDmmSamplerOpts({
            pool: pool,
            router: IKyberDmmRouter(router)
        }),
            WETH,
            USDC,
            takerTokenAmounts
        );
        assertGt(makerTokenAmounts[0], 0);
    }
}
