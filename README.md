# PiscineV1 - Pragma DEX Exercise

This project is part of the Pragma mentorship program for blockchain developers, created by [Alexandre Wolff](https://www.linkedin.com/in/alexandre-wolff/). It consists of implementing a Decentralized Exchange (DEX) protocol in Solidity and a backend service to interact with on-chain data.

## Project Overview

The project is divided into two main components:

1. **Protocol (Smart Contracts)**: A DEX implementation in Solidity
2. **Backend**: A Node.js/TypeScript service to interact with the blockchain

## Protocol Features

The DEX protocol enables:

- Liquidity providers to:
  - Deposit and withdraw any combination of ERC20 tokens into pools
  - Collect fees from trading activities
- Users to:
  - Exchange tokens while paying trading fees
  - Forward swaps to Uniswap V2 when no direct pool is available (with additional fees)

### Security Constraints

The protocol ensures:

- Liquidity can only be withdrawn by its rightful owners
- Token exchanges respect available pool liquidity

## Backend Features

The backend service provides:

- Pool listing with available tokens and their amounts
- Number of swaps performed on the protocol
- Protocol user address listing
- Liquidity provider address listing

## Project Structure Overview

```
piscine-v1/
├── backend/                    
│   ├── src/
│   │   └── index.ts           
│   ├── node_modules/         
│   ├── package.json           
│   └── ...                    
│
└── protocole/                 
    ├── script/     
    ├── src/
    │   ├── contracts/
    │   │   └── PiscineV1Exchange.sol
    │   │   └── PiscineV1Pool.sol          
    │   ├── interfaces/       
    │   └── libraries/       
    ├── test/
    │   └── CreatePool.t.sol              
    └── ...                 
```

## Smart Contract Architecture

The protocol is built around two main contracts:

### PiscineV1Exchange

- Acts as both a factory for pools and a router for transactions
- Provides getter functions for backend integration:
  - Number of pools
  - Pool balances

### PiscineV1Pool

- Deployed for each new liquidity pool
- Handles core DEX operations:
  - Adding liquidity
  - Removing liquidity
  - Token swaps

### Important Design Considerations

- Pool addresses are deterministically calculated based on token pairs
- Tokens are sorted in ascending order

This ensures that each token pair can only have one unique pool address

## Technology Stack

### Protocol

- **Framework**: Foundry
- **Language**: Solidity
- **Libraries**: OpenZeppelin

### Backend

- **Runtime**: Node.js
- **Language**: TypeScript
- **Frameworks**: Hono
- **Blockchain Interaction**: ethers.js
