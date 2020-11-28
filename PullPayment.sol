// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

contract Bid {
    // Public variables
    address public highestBidAddress;
    uint256 public highestBid;
    mapping(address => uint256) private deposits;

    // Events
    event NewHighestBid(address _bider, uint256 _amount);

    function deposit() public payable {
        deposits[msg.sender] += msg.value;
    }

    function bid(uint256 amount) public {
        require(
            highestBidAddress != msg.sender,
            "You are already the highestBider"
        );
        require(
            deposits[msg.sender] >= amount,
            "You don't have the necessary funds"
        );
        require(
            amount > highestBid,
            "Bid amount must be greater than current highest bid"
        );
        highestBidAddress = msg.sender;
        highestBid = amount;
        emit NewHighestBid(msg.sender, amount);
    }

    function withdraw() public {
        uint256 availableFunds = availableFunds();
        require(availableFunds > 0, "You do not have any funds to withdraw");
        deposits[msg.sender] -= availableFunds;
    }

    function availableFunds() public view returns (uint256) {
        uint256 amountBid = highestBidAddress == msg.sender ? highestBid : 0;
        return deposits[msg.sender] - amountBid;
    }
}
