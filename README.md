# NFT Collection (NftCollection)

## Overview

This project implements a simple ERC‑721‑style NFT collection on Ethereum using Solidity and Hardhat.  
It demonstrates how minting, transfers, approvals, and events work in a basic non‑fungible token contract.

## Collection Details

- **Name**: MyNFT  
- **Symbol**: MNFT  
- **Max Supply**: 1,000 tokens (configurable in the constructor)  
- **Standard Style**: ERC‑721‑like (not full OpenZeppelin implementation)

## Features

- Admin‑only minting with a fixed `maxSupply` cap.  
- `balanceOf` and `ownerOf` tracking for each token and address.  
- `transferFrom` and `safeTransferFrom` for moving tokens between accounts.  
- Single‑token `approve` and operator‑level `setApprovalForAll` permissions.  
- `mint` and `burn` functions that update `totalSupply` correctly.  
- `Transfer`, `Approval`, and `ApprovalForAll` events for transparency.  
- Optional base URI and per‑token `tokenURI` overrides for metadata.

## Project Structure

- `contracts/NftCollection.sol` – NFT collection contract.  
- `test/NftCollection.test.ts` – Automated test suite.  
- `hardhat.config.ts` – Hardhat configuration.  
- `Dockerfile` – Containerized environment for running tests.  
- `package.json` – Node.js dependencies and scripts.

## Running the Tests (Local)

From the project root:

```
npm install
npx hardhat compile
npx hardhat test
```

All 9 tests in `test/NftCollection.test.ts` should pass.

## Running the Tests (Docker)

Build the image:

```
docker build -t nft-collection .
```

Run the tests in a container:

```
docker run --rm nft-collection
```

The Dockerfile uses the `node:18-alpine` base image and automatically installs dependencies, compiles the contracts, and executes `npx hardhat test`.

## Assumptions

- Contract is intended as a learning/example NFT, not production‑ready.  
- `mint(address to, uint256 tokenId)` must be called with unique `tokenId` values.  
- Only the contract owner may mint; other callers will revert.
```

Do not add or remove any backticks (`). Just paste exactly this block.