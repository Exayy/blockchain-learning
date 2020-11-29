// static compiler version (with safemath compatibilitty)
pragma solidity 0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

contract Crowdsale {
    using SafeMath for uint256;

    address public owner; // the owner of the contract
    address payable public escrow; // wallet to collect raised ETH
    uint256 public savedBalance; // Total amount raised in ETH
    mapping(address => uint256) public balances; // Balances in incoming Ether

    // Events
    event Received(address payable, uint256 amount);
    event Withdraw(address payable, uint256 amount);

    // Initialization
    constructor(address payable _escrow) public {
        require(_escrow != address(0), "invalid escrow adress");
        owner = msg.sender;
        // add address of the specific contract
        escrow = _escrow;
    }

    // function to receive ETH
    receive() external payable {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        savedBalance = savedBalance.add(msg.value);
        escrow.send(msg.value);
        emit Received(msg.sender, msg.value);
    }

    // refund investisor
    function withdrawPayments() public {
        address payee = msg.sender;
        uint256 payment = balances[payee];

        savedBalance = savedBalance.sub(payment);
        balances[payee] = 0;
        payee.send(payment);
        emit Withdraw(msg.sender, msg.value);
    }
}
