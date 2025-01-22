/**
 * This file is autogenerated by Scaffold-ETH.
 * You should not edit it manually or your changes might be overwritten.
 */
import { GenericContractsDeclaration } from "~~/utils/scaffold-eth/contract";

const deployedContracts = {
  11155111: {
    SocialRecoveryWallet: {
      address: "0x080b89c411cfb9dc0d4aaef012cf8372aac305ca",
      abi: [
        {
          type: "constructor",
          inputs: [
            {
              name: "_guardians",
              type: "address[]",
              internalType: "address[]",
            },
          ],
          stateMutability: "nonpayable",
        },
        {
          type: "fallback",
          stateMutability: "nonpayable",
        },
        {
          type: "receive",
          stateMutability: "payable",
        },
        {
          type: "function",
          name: "addGuardian",
          inputs: [
            {
              name: "_guardian",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "call",
          inputs: [
            {
              name: "callee",
              type: "address",
              internalType: "address",
            },
            {
              name: "value",
              type: "uint256",
              internalType: "uint256",
            },
            {
              name: "data",
              type: "bytes",
              internalType: "bytes",
            },
          ],
          outputs: [],
          stateMutability: "payable",
        },
        {
          type: "function",
          name: "isGuardian",
          inputs: [
            {
              name: "guardian",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [
            {
              name: "",
              type: "bool",
              internalType: "bool",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "owner",
          inputs: [],
          outputs: [
            {
              name: "",
              type: "address",
              internalType: "address",
            },
          ],
          stateMutability: "view",
        },
        {
          type: "function",
          name: "removeGuardian",
          inputs: [
            {
              name: "_guardian",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "function",
          name: "signalNewOwner",
          inputs: [
            {
              name: "_proposedOwner",
              type: "address",
              internalType: "address",
            },
          ],
          outputs: [],
          stateMutability: "nonpayable",
        },
        {
          type: "event",
          name: "NewOwnerSignaled",
          inputs: [
            {
              name: "by",
              type: "address",
              indexed: false,
              internalType: "address",
            },
            {
              name: "proposedOwner",
              type: "address",
              indexed: false,
              internalType: "address",
            },
          ],
          anonymous: false,
        },
        {
          type: "event",
          name: "RecoveryExecuted",
          inputs: [
            {
              name: "newOwner",
              type: "address",
              indexed: false,
              internalType: "address",
            },
          ],
          anonymous: false,
        },
      ],
      inheritedFunctions: {},
    },
  },
} as const;

export default deployedContracts satisfies GenericContractsDeclaration;
