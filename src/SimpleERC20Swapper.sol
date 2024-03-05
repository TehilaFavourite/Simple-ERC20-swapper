// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IFactory} from "../src/interfaces/IFactory.sol";
import {IUniswapV2Router} from "../src/interfaces/IUniswapV2Router.sol";

contract SimpleERC20Swapper is Initializable, OwnableUpgradeable {
    IUniswapV2Router public router;
    IFactory public factory;

    event TokenSwapped(
        address indexed token,
        address indexed user,
        uint256 amount
    );
    event SetFactory(address indexed _factory);
    event SetRouterContract(address indexed _newRouter);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
    }

    function setFactory(address _factory) external onlyOwner {
        require(_factory != address(0), "invalid address");
        factory = IFactory(_factory);
        emit SetFactory(_factory);
    }

    function setRouterContract(address _newRouter) external onlyOwner {
        require(_newRouter != address(0), "invalid address");
        router = IUniswapV2Router(_newRouter);
        emit SetRouterContract(_newRouter);
    }

    function swapEtherToToken(
        address _token,
        uint256 _minAmount
    ) external payable returns (uint256) {
        require(msg.value > 0, "Invalid amount");
        address weth = router.WETH();
        address pairExist = factory.getPair(weth, _token);
        require(pairExist != address(0), "invalid pair");
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = _token;

        uint[] memory amounts = router.swapExactETHForTokens{value: msg.value}(
            _minAmount,
            path,
            address(this),
            block.timestamp
        );

        uint256 returnedAmount = amounts[1];
        require(returnedAmount >= _minAmount, "slippage not accepteable");

        IERC20(_token).transfer(msg.sender, returnedAmount);
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }

        return returnedAmount;
    }

    function withdrawStuckTokens(address token, uint amount) public onlyOwner {
        require(token != router.WETH(), "Cannot withdraw WETH");
        IERC20(token).transfer(owner(), amount);
    }

    receive() external payable {}
}
