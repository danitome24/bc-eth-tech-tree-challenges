//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import { console2 } from "forge-std/console2.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract EthStreaming is Ownable {
  event AddStream(address recipient, uint256 cap);
  event Withdraw(address recipient, uint256 amount);

  error EthStreaming__WithdrawFailed();
  error EthStreaming__NotEnoughFunds();
  error EthStreaming__NoStreamFound();
  error EthStreaming__WaitForNextWithdraw();

  uint256 public immutable unlockTime;

  struct Stream {
    uint256 cap;
    uint256 timeOfLastWithdrawal;
  }

  mapping(address => Stream) public streams;

  constructor(
    uint256 _unlockTime
  ) Ownable(msg.sender) {
    unlockTime = _unlockTime;
  }

  function addStream(address recipient, uint256 cap) external onlyOwner {
    streams[recipient] = Stream(cap, 0);
    emit AddStream(recipient, cap);
  }

  function withdraw(
    uint256 amount
  ) external {
    Stream storage stream = streams[msg.sender];
    if (stream.cap == 0) {
      revert EthStreaming__NoStreamFound();
    }

    uint256 elapsedTime = block.timestamp - stream.timeOfLastWithdrawal;
    uint256 unlockedAmount = (stream.cap * elapsedTime) / unlockTime;

    if (unlockedAmount > stream.cap) {
      unlockedAmount = stream.cap;
    }
    if (unlockedAmount > address(this).balance) {
      revert EthStreaming__NotEnoughFunds();
    }

    uint256 remainingAmount = unlockedAmount - amount;
    stream.timeOfLastWithdrawal =
      block.timestamp - ((remainingAmount * unlockTime) / stream.cap);

    (bool success,) = (msg.sender).call{ value: amount }("");
    if (!success) {
      revert EthStreaming__WithdrawFailed();
    }
    emit Withdraw(msg.sender, amount);
  }

  receive() external payable { }
}
