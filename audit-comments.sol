// Audit : compiler version should be completely specified
pragma solidity ^0.5.12;

contract Crowdsale {
    using SafeMath for uint256;

    address public owner; // the owner of the contract
    // Audit : escrow is a payable variable
    address public escrow; // wallet to collect raised ETH
    // Audit : There is no need to initialize variable (it's automatic) and will cost uncessary gas
    uint256 public savedBalance = 0; // Total amount raised in ETH
    mapping(address => uint256) public balances; // Balances in incoming Ether

    // Initialization
    // Audit : constructor() should be used instead of contract name function
    // Audit : _escrow is a payable variable
    function Crowdsale(address _escrow) public {
        // Audit : tx.origin shouldn't be used, use msg.sender instead
        // We also could use Ownable from openzepellin to have a standard contract ownership implementation
        owner = tx.origin;
        // add address of the specific contract
        // Audit : we could make sure that escrow address is not 0
        escrow = _escrow;
    }

    // function to receive ETH
    // Audit : use function receive instead
    function() public {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        savedBalance = savedBalance.add(msg.value);
        escrow.send(msg.value);
        // Audit : we could emit an event
    }

    // refund investisor
    function withdrawPayments() public {
        address payee = msg.sender;
        uint256 payment = balances[payee];

        // Audit : if msg.sender is a contract with another call to withdrawPayment
        //         it can create re-entrancy attack
        //         we could update balances[payee] before sending fund in order to avoid that
        payee.send(payment);

        savedBalance = savedBalance.sub(payment);
        balances[payee] = 0;
        // Audit : we could emit an event
    }
}
