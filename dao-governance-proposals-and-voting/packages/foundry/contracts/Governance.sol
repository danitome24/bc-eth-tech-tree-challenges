// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DecentralizedResistanceToken } from "./DecentralizedResistanceToken.sol";
import { console } from "forge-std/console.sol";

contract Governance {
  event ProposalCreated(uint256 proposalId, string title, uint256 votingDeadline, address creator);
  event VoteCasted(uint256 proposalId, address voter, uint8 vote, uint256 weight);
  event VotesRemoved(address voter, uint8 vote, uint256 weight);

  DecentralizedResistanceToken token;
  uint256 votingPeriod;

  /**
   * @dev Only one proposal can be active.
   */
  Proposal activeProposal;
  /**
   * @dev Only one proposal can be queued.
   */
  Proposal proposalQueue;
  uint8 nextProposalId;
  mapping(uint8 proposalId => mapping(address voter => bool hasVoted)) voterHasVoted;
  mapping(uint8 proposalId => mapping(address voter => uint8 vote)) voterVotes;

  struct Proposal {
    uint8 id;
    string title;
    uint256 deadline;
    address creator;
    uint256 againstVotesWeight;
    uint256 forVotesWeight;
    uint256 abstainVotesWeight;
  }

  constructor(address _tokenAddress, uint256 _votingPeriod) {
    token = DecentralizedResistanceToken(_tokenAddress);
    votingPeriod = _votingPeriod;
    nextProposalId = 1;
  }

  /**
   * Function to create new proposal.
   * @param _title Proposal title
   * @return proposalId Returns the proposalId.
   */
  function propose(
    string memory _title
  ) external onlyMember(msg.sender) rotateProposalsIfExpired returns (uint256) {
    if (activeProposal.creator == address(0) || activeProposal.deadline < block.timestamp) {
      activeProposal = _propose(_title);

      return activeProposal.id;
    } else if (proposalQueue.creator == address(0)) {
      proposalQueue = _propose(_title);

      return proposalQueue.id;
    }

    revert("One active / one queued proposal permitted");
  }

  function _propose(
    string memory _title
  ) private returns (Proposal memory) {
    uint8 proposalId = nextProposalId;
    Proposal memory proposal = Proposal(proposalId, _title, block.timestamp + votingPeriod, msg.sender, 0, 0, 0);

    emit ProposalCreated(proposalId, _title, votingPeriod, msg.sender);
    nextProposalId++;

    return proposal;
  }

  /**
   * Get proposal data given an id.
   * @param _proposalId  Proposal Id.
   * @return title Proposal title.
   * @return deadline Proposal deadline.
   * @return creator Proposl creator address.
   */
  function getProposal(
    uint256 _proposalId
  ) external view returns (string memory, uint256, address) {
    if (activeProposal.id == _proposalId) {
      return (activeProposal.title, activeProposal.deadline, activeProposal.creator);
    } else if (proposalQueue.id == _proposalId) {
      return (proposalQueue.title, proposalQueue.deadline, proposalQueue.creator);
    }

    revert("Proposal not found");
  }

  /**
   * Vote a proposal function.
   * @param _vote "Against" = 0 "For" = 1 "Abstain" = 2
   */
  function vote(
    uint8 _vote
  ) external onlyMember(msg.sender) {
    uint8 activeProposalId = activeProposal.id;
    if (activeProposalId == 0) {
      revert("No active proposal");
    }
    if (voterHasVoted[activeProposalId][msg.sender]) {
      revert("Caller has already voted");
    }
    if (activeProposal.deadline < block.timestamp) {
      revert("Vote period over");
    }
    uint256 voteWeight = token.balanceOf(msg.sender);
    if (_vote == 0) {
      activeProposal.againstVotesWeight += voteWeight;
    } else if (_vote == 1) {
      activeProposal.forVotesWeight += voteWeight;
    } else if (_vote == 2) {
      activeProposal.abstainVotesWeight += voteWeight;
    } else {
      revert("Invalid vote");
    }

    voterHasVoted[activeProposalId][msg.sender] = true;
    voterVotes[activeProposalId][msg.sender] = _vote;

    emit VoteCasted(activeProposal.id, msg.sender, _vote, voteWeight);
  }

  function removeVotes(
    address from
  ) external {
    if (msg.sender != address(token)) {
      revert("Only callable by token contract");
    }
    uint8 activeProposalId = activeProposal.id;
    uint256 voteWeight = token.balanceOf(from);
    uint8 voteByUser = voterVotes[activeProposalId][from];
    voterHasVoted[activeProposalId][from] = false;
    if (voteByUser == 0) {
      activeProposal.againstVotesWeight -= voteWeight;
    } else if (voteByUser == 1) {
      activeProposal.forVotesWeight -= voteWeight;
    } else if (voteByUser == 2) {
      activeProposal.abstainVotesWeight -= voteWeight;
    }

    emit VotesRemoved(from, voteByUser, voteWeight);
  }

  function getResult(
    uint256 _proposalId
  ) external view returns (bool) {
    if (activeProposal.id != _proposalId) {
      revert("Proposal not found");
    }
    if (activeProposal.deadline >= block.timestamp) {
      revert("Voting period not over yet");
    }
    return (activeProposal.forVotesWeight > activeProposal.againstVotesWeight);
  }

  modifier rotateProposalsIfExpired() {
    if (activeProposal.deadline < block.timestamp && proposalQueue.creator != address(0)) {
      activeProposal = proposalQueue;
      proposalQueue = Proposal(0, "", 0, address(0), 0, 0, 0);
    }
    _;
  }

  modifier onlyMember(
    address user
  ) {
    if (token.balanceOf(user) == 0) {
      revert("No token amount");
    }
    _;
  }
}
