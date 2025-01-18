//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WrappedETH is ERC20 {
  event Deposit(address depositor, uint256 amount);
  event Withdrawal(address withdrawer, uint256 amount);

  mapping(address sender => uint256 ethDeposited) sendersBalance;

  constructor() ERC20("WrappedETH", "WETH") { }

  function deposit() public payable {
    sendersBalance[msg.sender] += msg.value;
    _mint(msg.sender, msg.value);
    emit Deposit(msg.sender, msg.value);
  }

  function withdraw(
    uint256 amount
  ) external {
    require(amount >= sendersBalance[msg.sender], "Not enough balance");
    sendersBalance[msg.sender] -= amount;
    (bool success,) = (msg.sender).call{ value: amount }("");
    require(success, "Eth transfer failed");
    _burn(msg.sender, amount);
    emit Withdrawal(msg.sender, amount);
  }

  fallback() external { }

  receive() external payable {
    deposit();
  }
}
