// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Voting is Ownable {
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    // Events list
    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint256 proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted(address voter, uint256 proposalId);
    event VotesTallied();
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );

    uint256 public winningProposalId = 0; // Issue : proposal[0] is by default the winner
    Proposal[] public proposals;
    uint256 votersCount = 0;
    mapping(address => Voter) public voters;
    WorkflowStatus public workflowStatus = WorkflowStatus.RegisteringVoters;

    modifier onlyVoter {
        require(
            voters[msg.sender].isRegistered == true,
            "Only voter can call this function."
        );
        _;
    }

    function changeWorkflowStatus(WorkflowStatus newStatus) internal {
        emit WorkflowStatusChange(workflowStatus, newStatus);
        workflowStatus = newStatus;
    }

    // Voter registration [admin only]
    function addVoter(address _voterAddress) external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.RegisteringVoters,
            "This function can't be called because voters registering is closed"
        );
        require(
            voters[_voterAddress].isRegistered == false,
            "This voter has already been registered"
        );
        voters[_voterAddress] = Voter(true, false, 0);
        votersCount++;
        emit VoterRegistered(_voterAddress);
    }

    function startProposalsRegistration() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.RegisteringVoters,
            "This function can only be called when voters registering is still opened"
        );
        changeWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted);
        emit ProposalsRegistrationStarted();
    }

    function endProposalsRegistration() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "This function can't be called because proposal registering isn't opened"
        );
        changeWorkflowStatus(WorkflowStatus.ProposalsRegistrationEnded);
        emit ProposalsRegistrationEnded();
    }

    function startVotingSession() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationEnded,
            "This function can only be called when proposals registering is still opened"
        );
        changeWorkflowStatus(WorkflowStatus.VotingSessionStarted);
        emit VotingSessionStarted();
    }

    function endVotingSession() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.VotingSessionStarted,
            "This function can only be called if proposals registration is opened"
        );
        changeWorkflowStatus(WorkflowStatus.VotingSessionEnded);
        emit VotingSessionEnded();
    }

    function tally() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.VotingSessionEnded,
            "This function can only be called if vote session is closed and vote has not been tailed yet"
        );
        for (uint256 i = 1; i < proposals.length; i++) {
            if (
                proposals[i].voteCount > proposals[winningProposalId].voteCount
            ) {
                winningProposalId = i;
            }
        }
        changeWorkflowStatus(WorkflowStatus.VotesTallied);
        emit VotesTallied();
    }

    function addProposal(string memory _description) external onlyVoter {
        bool proposalExist = false;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (
                keccak256(abi.encode(proposals[i].description)) ==
                keccak256(abi.encode(_description))
            ) {
                proposalExist = true;
                break;
            }
        }
        require(
            bytes(_description).length > 0,
            "Proposal must have a description"
        );
        require(proposalExist == false, "This proposal already exist");
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "This function can only be called if proposals registration is opened"
        );
        proposals.push(Proposal(_description, 0));
        emit ProposalsRegistrationEnded();
    }

    function vote(uint256 _proposalId) external onlyVoter {
        require(
            workflowStatus == WorkflowStatus.VotingSessionStarted,
            "This function can only be called if voting session is opened"
        );

        require(voters[msg.sender].hasVoted == false, "You can only vote once");
        require(_proposalId < proposals.length, "This proposal doesn't exist");
        proposals[_proposalId].voteCount++;
        voters[msg.sender].hasVoted = true;
        emit Voted(msg.sender, _proposalId);
    }

    function getProposalCount() external view returns (uint256) {
        return proposals.length;
    }

    function getVoterCount() external view returns (uint256) {
        return votersCount;
    }

    function getWinningProposal() external view returns (string memory) {
        require(
            workflowStatus == WorkflowStatus.VotesTallied,
            "This function can only be called if vote is tallied"
        );
        require(
            proposals.length > 0,
            "There were no proposal during this vote"
        );
        return proposals[winningProposalId].description;
    }
}
