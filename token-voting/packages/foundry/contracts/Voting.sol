// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import { console2 } from "forge-std/console2.sol";
import { DecentralizedResistanceToken } from
  "./DecentralizedResistanceToken.sol";

contract Voting {
  error Voting__NotEnoughBalance(address who, uint256 balance);
  error Voting__VotingPeriodAlreadyPassed(uint256 periodForVoting);
  error Voting__VotingPeriodNotOverYet(uint256 periodForVoting);
  error Voting__UserAlreadyVoted(address who);
  error Voting__CanNotBeCalledByItselfs();

  event VoteCasted(address voter, bool vote, uint256 weight);
  event VotesRemoved(address voter, uint256 weight);

  DecentralizedResistanceToken s_drtToken;
  uint256 s_periodForVoting;
  mapping(address voter => bool hasVoted) public hasVoted;
  mapping(address voter => bool userVote) s_userVote;
  uint256 public votesFor;
  uint256 public votesAgainst;

  constructor(address _drtToken, uint256 periodForVoting) {
    s_drtToken = DecentralizedResistanceToken(_drtToken);
    s_periodForVoting = periodForVoting;
    votesFor = 0;
    votesAgainst = 0;
  }

  function vote(
    bool voteForOrAgainst
  ) public {
    if (s_drtToken.balanceOf(msg.sender) == 0) {
      revert Voting__NotEnoughBalance(msg.sender, 0);
    }

    if (block.timestamp > s_periodForVoting) {
      revert Voting__VotingPeriodAlreadyPassed(s_periodForVoting);
    }

    if (hasVoted[msg.sender]) {
      revert Voting__UserAlreadyVoted(msg.sender);
    }

    uint256 voteWeight = s_drtToken.balanceOf(msg.sender);

    if (voteForOrAgainst) {
      votesFor += voteWeight;
    } else if (!voteForOrAgainst) {
      votesAgainst += voteWeight;
    }
    hasVoted[msg.sender] = true;
    s_userVote[msg.sender] = voteForOrAgainst;

    emit VoteCasted(msg.sender, voteForOrAgainst, voteWeight);
  }

  function removeVotes(
    address from
  ) public {
    require(
      msg.sender == address(s_drtToken),
      "Function can only be called by the contract itself"
    );

    if (!hasVoted[from]) {
      return;
    }
    uint256 voteWeight = s_drtToken.balanceOf(from);
    bool votedFor = s_userVote[from];

    if (votedFor) {
      votesFor -= voteWeight;
    } else {
      votesAgainst -= voteWeight;
    }

    hasVoted[from] = false;

    emit VotesRemoved(from, voteWeight);
  }

  function getResult() public view returns (bool) {
    if (block.timestamp <= s_periodForVoting) {
      revert Voting__VotingPeriodNotOverYet(block.timestamp);
    }

    return (votesFor > votesAgainst);
  }
}
