// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract FundRaising {
    
    address payable public owner;
    uint public totalFundReq;
    uint public totalDonors;
    uint public totalVotes;
    uint public votingEndTime;
    uint public endTime;
    bool private initialFundClaimed;
    bool public fundFullyClaimed;
    bool public votingStatus;

    mapping(address => uint) public donors;
    mapping(address => bool) public voted;

    // Events
    event FundSent(address indexed donor, uint256 amount);
    event VotingStarted(address indexed starter, uint endTime);
    event Voted(address indexed voter);
    event FundClaimed(address indexed claimer, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the school can execute this");
        _;
    }

    modifier noReentrancy() {
        require(!fundFullyClaimed, "Reentrant call detected");
        _;
    }

    constructor(uint _totalFundReq, uint _endTime) {
        owner = payable(msg.sender);
        endTime = block.timestamp + _endTime;
        totalFundReq = _totalFundReq;
    }

    function sendFund() external payable {
        require(block.timestamp < endTime, "Deadline has passed !!");
        require(msg.sender != owner, "School cannot participate in fund raising!!");
        require(msg.value > 0, "Minimum contribution is 1");

        if(donors[msg.sender] == 0) {
            totalDonors++;
        }

        donors[msg.sender] += msg.value;

        emit FundSent(msg.sender, msg.value);
    }

    function getContractBalance() external view returns(uint) {
        return address(this).balance;
    }

    function startVoting(uint _votingEndTime) external onlyOwner {
        require(block.timestamp > endTime, "Deadline has not passed yet!!");
        votingEndTime = block.timestamp + _votingEndTime;
        votingStatus = true;

        emit VotingStarted(msg.sender, votingEndTime);
    }

    function putVote() external {
        require(votingStatus, "Voting has not started yet!!");
        require(block.timestamp < votingEndTime,"Voting time has passed!!");
        require(donors[msg.sender] != 0, "You're not eligible to vote as you haven't contributed!!");
        require(!voted[msg.sender], "You have already voted!!");

        totalVotes++;
        voted[msg.sender] = true;

        emit Voted(msg.sender);
    }

    function claimFund() external onlyOwner noReentrancy {
        require(block.timestamp > endTime, "Crowdfunding not over yet!!");
        
        if(!initialFundClaimed) {
            uint transferAmt = address(this).balance / 10;  //sending 10% of total fund raised;
            owner.transfer(transferAmt);
            initialFundClaimed = true;

            emit FundClaimed(msg.sender, transferAmt);
            return;
        }

        require(block.timestamp > votingEndTime, "Voting time has not yet passed!!");
        require(totalVotes > totalDonors / 2, "Majority does not support");
        fundFullyClaimed = true;

        uint transferAmt = address(this).balance;
        owner.transfer(transferAmt);

        emit FundClaimed(msg.sender, transferAmt);
    }
}
