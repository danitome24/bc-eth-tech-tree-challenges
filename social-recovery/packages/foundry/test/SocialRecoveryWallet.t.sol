// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "forge-std/StdUtils.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../contracts/SocialRecoveryWallet.sol";

contract Token is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
}

contract SocialRecoveryWalletTest is Test {
    SocialRecoveryWallet public socialRecoveryWallet;
    ERC20 public dai;

    address alice = makeAddr("alice");

    address guardian0 = makeAddr("guardian0");
    address guardian1 = makeAddr("guardian1");
    address guardian2 = makeAddr("guardian2");

    address[] chosenGuardianList = [guardian0, guardian1, guardian2];

    uint256 threshold = chosenGuardianList.length;

    address newOwner = makeAddr("newOwner");

    function setUp() public {
        // Use a different contract than default if CONTRACT_PATH env var is set
        string memory contractPath = vm.envOr("CONTRACT_PATH", string("none"));
        if (keccak256(abi.encodePacked(contractPath)) != keccak256(abi.encodePacked("none"))) {
            bytes memory args = abi.encode(chosenGuardianList);
            bytes memory bytecode = abi.encodePacked(vm.getCode(contractPath), args);
            address payable deployed;
            assembly {
                deployed := create(0, add(bytecode, 0x20), mload(bytecode))
            }
            socialRecoveryWallet = SocialRecoveryWallet(deployed);
        } else {
            socialRecoveryWallet = new SocialRecoveryWallet(chosenGuardianList);
        }
        dai = new Token("Dai", "DAI");
        // vm.deal(address(socialRecoveryWallet), 1 ether);
    }

    function testConstructorSetsGaurdians() public {
        assertTrue(socialRecoveryWallet.isGuardian(guardian0));
        assertTrue(socialRecoveryWallet.isGuardian(guardian1));
        assertTrue(socialRecoveryWallet.isGuardian(guardian2));

        address nonGuardian = makeAddr("nonGuardian");
        assertFalse(socialRecoveryWallet.isGuardian(nonGuardian));
    }

    function testCallRevertsWithCorrectError() public {
        vm.expectRevert();
        socialRecoveryWallet.call(address(this), 0, "");
    }

    function testCallCanForwardEth() public {
        uint256 initialValue = alice.balance;

        address recipient = alice;
        uint256 amountToSend = 1000;

        socialRecoveryWallet.call{value: amountToSend}(recipient, amountToSend, "");

        assertEq(alice.balance, initialValue + amountToSend);
    }

    function testCanHoldEth() public {
        uint256 initialValue = address(socialRecoveryWallet).balance;

        uint256 amountToSend = 1000;

        payable(address(socialRecoveryWallet)).transfer(amountToSend);

        assertEq(address(socialRecoveryWallet).balance, initialValue + amountToSend);
    }

    function testCanMoveHeldEth() public {
        uint256 initialValue = address(socialRecoveryWallet).balance;

        uint256 amountToSend = 1000;

        payable(address(socialRecoveryWallet)).transfer(amountToSend);

        assertEq(address(socialRecoveryWallet).balance, initialValue + amountToSend);

        socialRecoveryWallet.call(alice, amountToSend, "");
        assertEq(alice.balance, amountToSend);
    }

    function testCantCallIfNotOwner() public {
        uint256 initialValue = alice.balance;

        address recipient = alice;
        uint256 amountToSend = 1000;

        vm.expectRevert();
        vm.prank(alice);
        socialRecoveryWallet.call(recipient, amountToSend, "");

        assertEq(alice.balance, initialValue);
    }

    function testCallCanExecuteExternalTransactions() public {
        // Sending an ERC20 for example
        deal(address(dai), address(socialRecoveryWallet), 500);
        assertEq(dai.balanceOf(alice), 0);

        socialRecoveryWallet.call(address(dai), 0, abi.encodeWithSignature("transfer(address,uint256)", alice, 500));
        assertEq(dai.balanceOf(alice), 500);
    }

    function testCanOnlySignalNewOwnerIfGuardian() public {
        vm.expectRevert();
        vm.prank(alice);
        socialRecoveryWallet.signalNewOwner(alice);
    }

    function testSignalNewOwnerEmitsEvent() public {
        vm.expectEmit();
        emit SocialRecoveryWallet.NewOwnerSignaled(guardian0, newOwner);

        vm.prank(guardian0);
        socialRecoveryWallet.signalNewOwner(newOwner);
    }

    function testCanOnlySignalNewOwnerOnce() public {
        vm.prank(guardian0);
        socialRecoveryWallet.signalNewOwner(newOwner);

        // Try with original guardian
        vm.expectRevert();
        vm.prank(guardian0);
        socialRecoveryWallet.signalNewOwner(newOwner);

        vm.prank(guardian1);
        socialRecoveryWallet.signalNewOwner(newOwner);

        // Try with second guardian
        vm.expectRevert();
        vm.prank(guardian1);
        socialRecoveryWallet.signalNewOwner(newOwner);
    }

    function testSignalNewOwnerChangesOwnerOnceThresholdMet() public {
        helperChangeOwnerWithThreshold(newOwner);
    }

    function testSignalNewOwnerChangesOwnerTwoTimes() public {
        helperChangeOwnerWithThreshold(newOwner);
        address newOwner2 = makeAddr("newOwner2");
        helperChangeOwnerWithThreshold(newOwner2);
    }

    function testSignalNewOwnerEmitsEventWhenRecoveryExecuted() public {
        vm.prank(guardian0);
        socialRecoveryWallet.signalNewOwner(newOwner);

        vm.prank(guardian1);
        socialRecoveryWallet.signalNewOwner(newOwner);

        vm.expectEmit();
        emit SocialRecoveryWallet.RecoveryExecuted(newOwner);

        vm.prank(guardian2);
        socialRecoveryWallet.signalNewOwner(newOwner);
    }

    function testAddGuardian() public {
        address newGuardian = makeAddr("newGuardian");
        assertFalse(socialRecoveryWallet.isGuardian(newGuardian));

        vm.prank(socialRecoveryWallet.owner());
        socialRecoveryWallet.addGuardian(newGuardian);

        assertTrue(socialRecoveryWallet.isGuardian(newGuardian));
    }

    function testAddSameGuardianTwice() public {
        address newGuardian = makeAddr("newGuardian");
        assertFalse(socialRecoveryWallet.isGuardian(newGuardian));

        vm.prank(socialRecoveryWallet.owner());
        socialRecoveryWallet.addGuardian(newGuardian);

        assertTrue(socialRecoveryWallet.isGuardian(newGuardian));

        // Try to add the same guardian again
        vm.prank(socialRecoveryWallet.owner());
        vm.expectRevert();
        socialRecoveryWallet.addGuardian(newGuardian);
    }

    function testCantAddGuardianIfNotOwner() public {
        address newGuardian = makeAddr("newGuardian");
        assertFalse(socialRecoveryWallet.isGuardian(newGuardian));

        vm.expectRevert();
        vm.prank(alice);
        socialRecoveryWallet.addGuardian(newGuardian);

        assertFalse(socialRecoveryWallet.isGuardian(newGuardian));
    }

    function testCantRemoveGuardianIfNotOwner() public {
        assertTrue(socialRecoveryWallet.isGuardian(guardian0));

        vm.expectRevert();
        vm.prank(alice);
        socialRecoveryWallet.removeGuardian(guardian0);

        assertTrue(socialRecoveryWallet.isGuardian(guardian0));
    }

    function testRemoveGuardian() public {
        assertTrue(socialRecoveryWallet.isGuardian(guardian0));

        vm.prank(socialRecoveryWallet.owner());
        socialRecoveryWallet.removeGuardian(guardian0);

        assertFalse(socialRecoveryWallet.isGuardian(guardian0));
    }

    function testRemoveNonExistantGuardian() public {
        // // Try to remove address that was never a guardian
        vm.prank(socialRecoveryWallet.owner());
        vm.expectRevert();
        socialRecoveryWallet.removeGuardian(alice);
    }

    function helperChangeOwnerWithThreshold(address _newOwner) internal {

        vm.prank(guardian0);
        socialRecoveryWallet.signalNewOwner(_newOwner);

        vm.prank(guardian1);
        socialRecoveryWallet.signalNewOwner(_newOwner);

        vm.prank(guardian2);
        socialRecoveryWallet.signalNewOwner(_newOwner);

        assertEq(socialRecoveryWallet.owner(), _newOwner);
    }
}