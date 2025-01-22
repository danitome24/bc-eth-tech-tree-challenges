// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { console2 } from "forge-std/console2.sol";

contract DeadMansSwitch {
  /////////////////
  //// STRUCTS ////
  /////////////////

  ////////////////
  //// EVENTS ////
  ////////////////
  event CheckIn(address account, uint256 timestamp);
  event BeneficiaryAdded(address user, address beneficiary);
  event BeneficiaryRemoved(address user, address beneficiary);
  event Deposit(address depositor, uint256 amount);
  event Withdrawal(address beneficiary, uint256 amount);

  /////////////////////////
  //// STATE VARIABLES ////
  /////////////////////////
  mapping(address account => uint256 interval) accountCheckInInterval;
  mapping(address accont => uint256 lastCheckIn) accountLastCheckIn;
  mapping(address account => uint256 balance) balances;
  mapping(address account => address[] beneficiaries) beneficiaries;
  mapping(address account => mapping(address beneficiary => bool isBeneficiary))
    isBeneficiary;

  receive() external payable {
    deposit();
  }

  fallback() external payable {
    deposit();
  }

  constructor() { }

  ////////////////////////////
  //// EXTERNAL FUNCTIONS ////
  ////////////////////////////
  function setCheckInInterval(
    uint256 interval
  ) external {
    require(interval > 0, "Interval must be greater than 0");
    accountCheckInInterval[msg.sender] = interval;
    checkIn();
  }

  function checkIn() public {
    accountLastCheckIn[msg.sender] = block.timestamp;
    emit CheckIn(msg.sender, block.timestamp);
  }

  function addBeneficiary(
    address beneficiary
  ) external {
    require(beneficiary != address(0), "Address must be different than 0");
    require(
      !isBeneficiary[msg.sender][beneficiary], "Account already beneficiary"
    );
    beneficiaries[msg.sender].push(beneficiary);
    isBeneficiary[msg.sender][beneficiary] = true;
    checkIn();
    emit BeneficiaryAdded(msg.sender, beneficiary);
  }

  function removeBeneficiary(
    address beneficiary
  ) external {
    require(beneficiary != address(0), "Address must be different than 0");
    bool beneficiaryRemoved = false;
    uint256 numOfBeneficiaries = beneficiaries[msg.sender].length;
    for (uint256 i = 0; i < numOfBeneficiaries; i++) {
      if (beneficiaries[msg.sender][i] == beneficiary) {
        delete beneficiaries[msg.sender][i];
        beneficiaryRemoved = true;
        isBeneficiary[msg.sender][beneficiary] = false;
        break;
      }
    }

    if (!beneficiaryRemoved) {
      revert();
    }
    checkIn();
    emit BeneficiaryRemoved(msg.sender, beneficiary);
  }

  function deposit() public payable {
    balances[msg.sender] += msg.value;
    checkIn();
    emit Deposit(msg.sender, msg.value);
  }

  function withdraw(address account, uint256 amount) external {
    require(account != address(0), "Address must be different than zero");
    require(amount > 0, "Amount to withdraw must be greater than zero");
    require(balances[account] >= amount, "Not enough balance to withdraw");

    if (msg.sender == account) {
      _withdrawFunds(account, amount);
    } else if (
      isBeneficiary[account][msg.sender] && _hasIntervalPassed(account)
    ) {
      _withdrawFunds(account, amount);
    } else {
      revert();
    }
    checkIn();
  }

  /////////////////////////
  //// VIEW FUNCTIONS /////
  /////////////////////////
  function balanceOf(
    address account
  ) external view returns (uint256) {
    require(account != address(0), "Address must be different than 0");
    return balances[account];
  }

  function lastCheckIn(
    address account
  ) external view returns (uint256) {
    require(account != address(0), "Address must be different than 0");
    return accountLastCheckIn[account];
  }

  function checkInInterval(
    address account
  ) external view returns (uint256) {
    return accountCheckInInterval[account];
  }

  //////////////////////////
  //// PRIVATE FUNCTIONS////
  //////////////////////////
  function _withdrawFunds(address account, uint256 amount) private {
    (bool success,) = (msg.sender).call{ value: amount }("");
    require(success, "Error on withdrawal");
    balances[account] -= amount;

    emit Withdrawal(account, amount);
  }

  function _hasIntervalPassed(
    address account
  ) private view returns (bool) {
    return accountCheckInInterval[account]
      < block.timestamp - accountLastCheckIn[account];
  }
}
