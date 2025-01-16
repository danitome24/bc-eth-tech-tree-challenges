//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Multisend {
  ////////////////
  ////  Errors
  ////////////////
  error Multisend__NotValidLengths();
  error Multisend__ETHTransferFailed(address receiver, uint256 amount);

  ////////////////
  ////  Events
  ////////////////
  event SuccessfulETHTransfer(
    address _sender, address payable[] _receivers, uint256[] _amounts
  );
  event SuccessfulTokenTransfer(
    address indexed _sender,
    address[] indexed _receivers,
    uint256[] _amounts,
    address _token
  );

  constructor() { }

  /////////////////////////
  ////  External functions
  /////////////////////////
  function sendETH(
    address payable[] calldata receivers,
    uint256[] calldata amounts
  ) external payable {
    if (receivers.length != amounts.length) {
      revert Multisend__NotValidLengths();
    }
    _sentETHToAllReceivers(receivers, amounts);
    emit SuccessfulETHTransfer(msg.sender, receivers, amounts);
  }

  function sendTokens(
    address[] calldata receivers,
    uint256[] calldata amounts,
    address token
  ) external {
    if (receivers.length != amounts.length) {
      revert Multisend__NotValidLengths();
    }
    _sendTokensToAllReceivers(receivers, amounts, token);
    emit SuccessfulTokenTransfer(msg.sender, receivers, amounts, token);
  }

  receive() external payable { }

  /////////////////////////
  ////  Private Functions
  /////////////////////////
  function _sentETHToAllReceivers(
    address payable[] calldata receivers,
    uint256[] calldata amounts
  ) private {
    uint256 loopLength = receivers.length;
    for (uint256 i = 0; i < loopLength; i++) {
      (bool success,) = (receivers[i]).call{ value: amounts[i] }("");
      if (!success) {
        revert Multisend__ETHTransferFailed(receivers[i], amounts[i]);
      }
    }
  }

  function _sendTokensToAllReceivers(
    address[] calldata receivers,
    uint256[] calldata amounts,
    address tokenAddr
  ) private {
    uint256 loopLength = receivers.length;
    IERC20 token = IERC20(tokenAddr);
    for (uint256 i = 0; i < loopLength; i++) {
      bool success = token.transferFrom(msg.sender, receivers[i], amounts[i]);
      if (!success) {
        revert Multisend__ETHTransferFailed(receivers[i], amounts[i]);
      }
    }
  }
}
