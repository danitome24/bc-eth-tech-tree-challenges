// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DecentralizedResistanceToken } from
  "./DecentralizedResistanceToken.sol";

contract Governance {
  event ProposalCreated(uint proposalId, string title, uint votingDeadline, address creator);

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
    string title;
    uint256 deadline;
  }

  constructor(address _tokenAddress, uint256 _votingPeriod) {
    token = DecentralizedResistanceToken(_tokenAddress);
    votingPeriod = _votingPeriod;
    nextProposalId = 0;
  }

  /**
   * Function to create new proposal.
   * @param _title Proposal title
   * @return proposalId Returns the proposalId.
   */
  function propose(string memory _title) external returns(uint256) {
    uint256 proposalId = nextProposalId;
    activeProposal = Proposal(_title, votingPeriod);

    emit ProposalCreated(proposalId, _title, votingPeriod, msg.sender);
    nextProposalId++;

    return proposalId;
  }
}
