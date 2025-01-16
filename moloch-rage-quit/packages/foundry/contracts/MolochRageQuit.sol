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
  event Voted(uint256 proposalId, address member);
  event ProposalExecuted(uint256 proposalId);
  event RageQuit(address member, uint256 returnedETH);

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
  uint256 totalMembers;
  uint256 totalShares;

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
    require(deadline > block.timestamp, "Deadline must be greater than current timestamp");
    _createProposal(contractToCall, data, deadline, msg.sender);
  }

  function addMember(address newMember, uint256 shares) external {
    require(msg.sender == address(this), "Only callable by itself");
    _addMember(newMember, shares);
  }

  function vote(
    uint256 proposalId
  ) external {
    require(membersToShares[msg.sender] > 0, "Non-members cannot vote");
    require(idToProposal[proposalId].proposer != address(0), "Proposal not exists");
    _vote(proposalId, msg.sender);
  }

  function executeProposal(
    uint256 proposalId
  ) external {
    require(idToProposal[proposalId].proposer != address(0), "Proposal not exists");
    Proposal storage proposal = idToProposal[proposalId];
    require(proposal.deadline < block.timestamp, "Deadline not passed yet");
    require(proposal.votes > (totalMembers / 2), "No majority votes");

    (bool success, bytes memory returnData) = (proposal.contractToCall).call(proposal.dataToCallWith);
    require(success, string(abi.encodePacked("Call failed: ", returnData)));
    emit ProposalExecuted(proposalId);
  }

  function rageQuit() external {
    uint256 memberShare = membersToShares[msg.sender];
    require(memberShare > 0, "Non-members cannot vote");

    uint256 memberPortion = (memberShare * address(this).balance) / totalShares;
    (bool success,) = (msg.sender).call{ value: memberPortion }("");
    require(success, "Sending ETH failed");
    membersToShares[msg.sender] = 0;
    totalMembers--;
    totalShares -= memberShare;
    emit RageQuit(msg.sender, memberPortion);
  }

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
  ) external view returns (bool) {
    return (membersToShares[msg.sender] > 0);
  }

  receive() external payable {}

  /////////////////////////
  ///// Private Functions
  /////////////////////////

  function _incrementProposalId() private {
    nextProposalId++;
  }

  function _createProposal(address contractToCall, bytes calldata data, uint256 deadline, address proposer) private {
    Proposal storage newProposal = idToProposal[nextProposalId];

    newProposal.proposer = proposer;
    newProposal.contractToCall = contractToCall;
    newProposal.dataToCallWith = data;
    newProposal.deadline = deadline;
    newProposal.votes = 0;

    emit ProposalCreated(nextProposalId, proposer, contractToCall, data, deadline);

    _incrementProposalId();
  }

  function _addMember(address newMember, uint256 shares) private {
    membersToShares[newMember] = shares;
    totalMembers++;
    totalShares += shares;
    emit MemberAdded(newMember);
  }

  function _vote(uint256 proposalId, address by) private {
    Proposal storage proposal = idToProposal[proposalId];

    require(!proposal.voters[by], "Member already voted");

    proposal.votes += membersToShares[by];
    proposal.voters[by] = true;
    emit Voted(proposalId, by);
  }
}
