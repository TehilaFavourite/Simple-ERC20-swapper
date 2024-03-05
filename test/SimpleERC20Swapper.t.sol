// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Test, console2} from "forge-std/Test.sol";
// import {Counter} from "../src/Counter.sol";
import {SimpleERC20Swapper} from "../src/SimpleERC20Swapper.sol";

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract SimpleERC20SwapperTest is Test {
    SimpleERC20Swapper public simpleERC20Swapper;
    address simpleERC20SwapperProxy;
    address owner;
    address factory;
    address router;
    address usdc;

    function setUp() public {
        uint256 forkId = vm.createFork(
            "https://eth-mainnet.g.alchemy.com/v2/YNpzytqu2p1u2S5AUANzbWRKwP5KCnaX"
        );
        vm.selectFork(forkId);
        owner = address(22222);
        factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        router = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

        vm.startPrank(owner);
        // deploy swapper
        simpleERC20Swapper = new SimpleERC20Swapper();

        // Deploy proxy and initialize to logic contract
        bytes memory initData = abi.encodeWithSelector(
            simpleERC20Swapper.initialize.selector,
            owner
        );

        simpleERC20SwapperProxy = address(
            new TransparentUpgradeableProxy(
                address(simpleERC20Swapper),
                owner,
                initData
            )
        );

        // Get proxy contract instance
        simpleERC20Swapper = SimpleERC20Swapper(
            payable(simpleERC20SwapperProxy)
        );

        simpleERC20Swapper.setFactory(factory);
        simpleERC20Swapper.setRouterContract(router);

        // request for ether
        deal(owner, 10 ether);

        vm.stopPrank();
    }

    function test_swapper() external {
        vm.startPrank(owner);
        // get owner balance first
        uint256 ownerBalanceBefore = IERC20(usdc).balanceOf(owner);
        console2.log("Owner balance before swap: ", ownerBalanceBefore);

        // get owner
        address getOwner = simpleERC20Swapper.owner();
        console2.log("get owner: ", getOwner);

        simpleERC20Swapper.swapEtherToToken{value: 5 ether}(usdc, 1);

        // get owner balance after swap
        uint256 ownerBalanceAfter = IERC20(usdc).balanceOf(owner);
        console2.log("Owner balance after swap: ", ownerBalanceAfter);
        vm.stopPrank();
    }
}
