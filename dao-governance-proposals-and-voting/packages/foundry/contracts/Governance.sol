// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DecentralizedResistanceToken } from "./DecentralizedResistanceToken.sol";
import {console} from "forge-std/console.sol";

contract Governance {
  event ProposalCreated(uint256 proposalId, string title, uint256 votingDeadline, address creator);

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

  struct Proposal {
    uint256 id;
    string title;
    uint256 deadline;
    address creator;
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
  ) external returns (uint256) {
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
    uint256 proposalId = nextProposalId;
    Proposal memory proposal = Proposal(proposalId, _title, block.timestamp + votingPeriod, msg.sender);

    emit ProposalCreated(proposalId, _title, votingPeriod, msg.sender);
    nextProposalId++;

    return proposal;
  }

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
}
