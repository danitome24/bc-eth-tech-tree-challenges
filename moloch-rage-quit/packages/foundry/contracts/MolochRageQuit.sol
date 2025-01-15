//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { console2 } from "forge-std/console2.sol";

contract MolochRageQuit {
  event ProposalCreated(
    uint256 proposalId,
    address proposer,
    address contractToCall,
    bytes dataToCallWith,
    uint256 deadline
  );
  event MemberAdded(address newMember);

  uint256 deployerShares;

  constructor(
    uint256 _deployerShares
  ) {
    deployerShares = _deployerShares;
  }

  function propose(
    address contractToCall,
    bytes calldata data,
    uint256 deadline
  ) external { }

  function addMember(address newMember, uint256 shares) external { }

  function vote(
    uint256 proposalId
  ) external { }

  function executeProposal(
    uint256 proposalId
  ) external { }

  function rageQuit() external { }

  function getProposal(
    uint256 proposalId
  )
    external
    view
    returns (
      address proposer,
      address contractAddr,
      bytes memory data,
      uint256 votes,
      uint256 deadline
    )
  { }

  function isMember(address) external view returns (address) {}
}
