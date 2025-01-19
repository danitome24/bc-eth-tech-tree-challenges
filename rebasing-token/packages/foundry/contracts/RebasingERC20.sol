// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { console2 } from "forge-std/console2.sol";

contract RebasingERC20 is Ownable {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Rebase(uint256 newTotalSupply);

  ///////////////////
  // State variables
  ///////////////////
  uint256 _totalSupply;
  string constant tokenName = "Rebasing Token";
  string constant tokenSymbol = "RBT";

  mapping(address holder => uint256 balance) holderBalances;
  mapping(address owner => mapping(address spender => uint256 amount)) private
    _allowances;

  address[] private holders;
  mapping(address holder => bool isHolder) isHolder;

  constructor(
    uint256 initialSupply
  ) Ownable(msg.sender) {
    _totalSupply = initialSupply;
    holderBalances[msg.sender] = initialSupply;
    _addHolderIfNeeded(msg.sender);
    emit Transfer(address(0), msg.sender, initialSupply);
  }

  function rebase(
    int256 amountToRebase
  ) external onlyOwner {
    uint256 oldTotalSupply = _totalSupply;
    _updateTotalSupply(amountToRebase);
    _updateHoldersBalance(oldTotalSupply, _totalSupply);
    emit Rebase(_totalSupply);
  }

  function transfer(address to, uint256 value) public {
    require(holderBalances[msg.sender] >= value);
    holderBalances[msg.sender] -= value;
    holderBalances[to] += value;

    _addHolderIfNeeded(to);
    _removeHolderIfNeeded(msg.sender);

    emit Transfer(msg.sender, to, value);
  }

  function transferFrom(address from, address to, uint256 value) public {
    require(balanceOf(from) >= value, "Not enough balance");
    require(_allowances[from][to] >= value, "Allowance excedded");
    holderBalances[from] -= value;
    holderBalances[to] += value;
    _allowances[from][to] -= value;

    _addHolderIfNeeded(to);
    _removeHolderIfNeeded(from);

    emit Transfer(from, to, value);
  }

  function balanceOf(
    address account
  ) public view returns (uint256) {
    return holderBalances[account];
  }

  function approve(address spender, uint256 amount) public returns (bool) {
    _allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function allowance(
    address owner,
    address spender
  ) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  function decimals() external pure returns (uint256) {
    return 18;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function _updateTotalSupply(
    int256 amountToRebase
  ) private {
    if (amountToRebase >= 0) {
      _totalSupply += uint256(amountToRebase);
    } else if (amountToRebase < 0) {
      _totalSupply -= uint256(-amountToRebase);
    }
  }

  function _updateHoldersBalance(
    uint256 oldTotalSupply,
    uint256 newTotalSupply
  ) private {
    uint256 holdersLength = holders.length;
    for (uint256 index = 0; index < holdersLength; index++) {
      address holder = holders[index];
      holderBalances[holder] =
        balanceOf(holder) * newTotalSupply / oldTotalSupply;
    }
  }

  function _addHolderIfNeeded(
    address holder
  ) private {
    if (!isHolder[holder]) {
      holders.push(holder);
      isHolder[holder] = true;
    }
  }

  function _removeHolderIfNeeded(
    address holder
  ) private {
    if (isHolder[holder] && balanceOf(holder) == 0) {
      isHolder[holder] = false;
      for (uint256 i = 0; i < holders.length; i++) {
        if (holders[i] == holder) {
          holders[i] = holders[holders.length - 1];
          holders.pop();
          break;
        }
      }
    }
  }
}
