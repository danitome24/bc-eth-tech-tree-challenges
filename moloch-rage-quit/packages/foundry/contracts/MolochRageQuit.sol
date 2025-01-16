//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { console2 } from "forge-std/console2.sol";

contract MolochRageQuit {
  ///////////////////
  ///// Events
  ///////////////////
  event ProposalCreated(
    uint256 proposalId, address proposer, address contractToCall, bytes dataToCallWith, uint256 deadline
  );
  event MemberAdded(address newMember);

  ///////////////////
  ///// Structs
  ///////////////////
  struct Proposal {
    address proposer;
    address contractToCall;
    bytes dataToCallWith;
    uint256 deadline;
    uint256 votes;
    mapping(address voter => bool hasVoted) voters;
  }

  ///////////////////
  ///// Storage variables
  ///////////////////
  uint256 nextProposalId;
  mapping(uint256 proposalId => Proposal proposal) idToProposal;
  mapping(address member => uint256 shares) membersToShares;

  ///////////////////
  ///// Constructor
  ///////////////////
  constructor(
    uint256 _deployerShares
  ) {
    _addMember(msg.sender, _deployerShares);
    nextProposalId = 1;
  }

  /////////////////////////
  ///// External Functions
  /////////////////////////
  function propose(address contractToCall, bytes calldata data, uint256 deadline) external {
    require(contractToCall != address(0), "Contract address cannot be zero");
    require(membersToShares[msg.sender] > 0, "No Members cannot propose");
    _createProposal(contractToCall, data, deadline);
  }

  function addMember(address newMember, uint256 shares) private {
    // Only can be called by itself.
    require(msg.sender == address(this), "Only callable by itself");
    _addMember(newMember, shares);
  }

  function vote(
    uint256 proposalId
  ) external {
    // Revert if called by non-member.
    // Revert if voter has already voted.
    // Revert if proposal does not exist.
    // Vote then
  }

  function executeProposal(
    uint256 proposalId
  ) external { }

  function rageQuit() external { }

  /////////////////////////
  ///// View Functions
  /////////////////////////
  function getProposal(
    uint256 proposalId
  ) external view returns (address proposer, address contractAddr, bytes memory data, uint256 votes, uint256 deadline) {
    Proposal storage proposal = idToProposal[proposalId];

    return (proposal.proposer, proposal.contractToCall, proposal.dataToCallWith, proposal.votes, proposal.deadline);
  }

  function isMember(
    address
  ) external view returns (address) { }

  /////////////////////////
  ///// Private Functions
  /////////////////////////
  function _incrementProposalId() private {
    nextProposalId++;
  }

  function _createProposal(address contractToCall, bytes calldata data, uint256 deadline) private {
    Proposal storage newProposal = idToProposal[nextProposalId];

    newProposal.proposer = msg.sender;
    newProposal.contractToCall = contractToCall;
    newProposal.dataToCallWith = data;
    newProposal.deadline = deadline;
    newProposal.votes = 0;

    emit ProposalCreated(nextProposalId, msg.sender, contractToCall, data, deadline);

    _incrementProposalId();
  }

  function _addMember(address newMember, uint256 shares) private {
    membersToShares[newMember] = shares;
  }
}
