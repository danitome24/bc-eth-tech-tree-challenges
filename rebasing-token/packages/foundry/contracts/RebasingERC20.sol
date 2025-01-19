// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {console2} from "forge-std/console2.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Good luck!

contract RebasingERC20 is ERC20, Ownable {

    uint256 public currentSupply;

    event Rebase(uint256 currentSupply);


    constructor(uint256 _totalSupply) ERC20("Rebasing Token", "$RBT") Ownable(msg.sender){
        _mint(msg.sender, _totalSupply);
        currentSupply = _totalSupply;
    }

    function rebase(int256 amount) external onlyOwner {
        if (amount < 0) {
            currentSupply = currentSupply - uint256(-amount);
        } else {
            currentSupply = currentSupply + uint256(amount);
        }        
        emit Rebase(currentSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return currentSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account) * currentSupply / super.totalSupply();
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 currentBalance = balanceOf(msg.sender);
        require(currentBalance >= amount, "Insufficient balance");
        _transfer(msg.sender, to, amount * super.totalSupply() / currentSupply);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 currentBalance = balanceOf(from);
        uint256 currentAllowance = allowance(from, to);
        require(currentBalance >= amount, "Insufficient balance");
        _transfer(from, to, amount * super.totalSupply() / currentSupply);
        if (currentAllowance > amount) {
            _approve(from, to, (currentAllowance - amount));
        }
        return true;
    }

}