//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import { console2 } from "forge-std/console2.sol";

contract SocialRecoveryWallet {
  /////////////////
  //// STRUCTS ////
  /////////////////

  //////////////////
  ///// Events /////
  //////////////////
  event NewOwnerSignaled(address by, address proposedOwner);
  event RecoveryExecuted(address newOwner);

  //////////////////////
  ///// STATE VARS /////
  //////////////////////
  address public owner;
  uint256 totalGuardians;
  mapping(address guardian => bool isGuardian) guardians;
  mapping(address proposedGuardian => mapping(address guardian => bool signal))
    hasGuardianSignaled;
  mapping(address proposedGuardian => uint256 guardiansSignaled)
    numGuardiansSignaled;

  receive() external payable { }

  fallback() external { }

  constructor(
    address[] memory _guardians
  ) {
    owner = msg.sender;
    for (uint256 i = 0; i < _guardians.length; i++) {
      guardians[_guardians[i]] = true;
    }
    totalGuardians = _guardians.length;
  }

  //////////////////////////
  ///// EXTERNAL FUNCS /////
  //////////////////////////
  function call(
    address callee,
    uint256 value,
    bytes calldata data
  ) external payable {
    require(msg.sender == owner, "Only the owner can call this function");
    (bool success,) = callee.call{ value: value }(data);
    require(success, "Call failed");
  }

  function signalNewOwner(
    address _proposedOwner
  ) external {
    require(guardians[msg.sender], "Only guardian");
    require(
      !hasGuardianSignaled[_proposedOwner][msg.sender], "Can only signal once"
    );

    hasGuardianSignaled[_proposedOwner][msg.sender] = true;
    numGuardiansSignaled[_proposedOwner]++;
    emit NewOwnerSignaled(msg.sender, _proposedOwner);

    // all guardians have signaled.
    if (totalGuardians == numGuardiansSignaled[_proposedOwner]) {
      owner = _proposedOwner;
      emit RecoveryExecuted(_proposedOwner);
    }
  }

  function addGuardian(
    address _guardian
  ) external {
    require(msg.sender == owner, "Only owner can add guardian");
    require(_guardian != address(0), "Address must be different than zero");
    require(!guardians[_guardian], "Only can be added once");
    guardians[_guardian] = true;
    totalGuardians++;
  }

  function removeGuardian(
    address _guardian
  ) external {
    require(msg.sender == owner, "Only owner can add guardian");
    require(_guardian != address(0), "Address must be different than zero");
    require(guardians[_guardian], "Guardian not found");
    guardians[_guardian] = false;
    totalGuardians--;
  }

  function isGuardian(
    address guardian
  ) external view returns (bool) {
    return guardians[guardian];
  }
}
