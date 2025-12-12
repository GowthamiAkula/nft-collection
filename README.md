This is a full `README.md` you can paste directly into your project.

***

```md
# NFT Collection Hardhat Project

This repository contains a basic ERC‑721‑style NFT collection smart contract (`NftCollection`) and a complete automated test suite using Hardhat, TypeScript/JavaScript, and Docker.

The goal is to provide a minimal but realistic NFT contract with deployment‑ready tests that can be executed locally or in a containerized environment.

## Project Structure

- `contracts/NftCollection.sol` – Solidity contract implementing a simple ERC‑721‑like NFT collection.
- `test/NftCollection.test.ts` – Test suite covering deployment, minting, transfers, approvals, reverts, and events.
- `hardhat.config.ts` – Hardhat configuration (solidity version, plugins, paths).
- `Dockerfile` – Container definition used to run the tests in an isolated environment.
- `package.json` – Node.js dependencies and scripts.
- `artifacts/`, `cache/`, `node_modules/` – Generated build and dependency folders.

## Tools and Versions

- **Solidity**: `0.8.28`
- **Hardhat**: 2.x
- **Node.js**: Tested with Node 18 (container uses `node:18-alpine`)
- **Ethers.js**: 6.x
- **Testing framework**: Mocha + Chai with Hardhat matchers
- **Container runtime**: Docker

> Note: Hardhat may show a warning about specific Node.js patch versions, but the suite is known to run successfully with Node 18.

## Contract Overview

`NftCollection` implements a simplified ERC‑721‑style NFT with:

- **Collection configuration**
  - Name, symbol, max supply, and tracked total supply.
- **Ownership and approvals**
  - `ownerOf`, `balanceOf`
  - Single‑token `approve` / `getApproved`
  - Operator approvals via `setApprovalForAll` / `isApprovedForAll`
- **Transfers**
  - `transferFrom`
  - `safeTransferFrom` overloads
- **Minting and burning**
  - `mint(address to, uint256 tokenId)` restricted to the contract owner and respecting `maxSupply`
  - `burn(uint256 tokenId)` for owners or approved operators
- **Admin controls**
  - Pausing/unpausing minting
  - Updating base token URI
  - Transferring contract ownership
- **Metadata**
  - Optional base URI and per‑token URI overrides
  - `tokenURI(uint256 tokenId)` with simple numeric ID to string conversion

## Test Suite

All tests live in `test/NftCollection.test.ts`. Each test deploys a fresh contract instance to an in‑memory Hardhat network.

Covered behaviors:

- Initial configuration:
  - Correct `name`, `symbol`, `maxSupply`, and `totalSupply == 0`.
- Access control:
  - Minting is admin‑only; non‑owner mint attempts revert with `"Only owner"`.
- Minting:
  - Successful mint increments `totalSupply`, assigns `ownerOf(tokenId)`, and updates `balanceOf`.
  - Minting beyond `_maxSupply` reverts with `"Max supply reached"`.
- Transfers:
  - Direct transfers update balances and `ownerOf` correctly.
  - Transfers of non‑existent tokens revert with `"Operator query for nonexistent token"`.
- Approvals:
  - Single‑token approvals allow an approved address to transfer the token.
  - Operator approvals (`setApprovalForAll`) allow an operator to transfer multiple tokens.
- Events:
  - `Transfer`, `Approval`, and `ApprovalForAll` events are emitted with the correct parameters for minting, approvals, and transfers.

Running the suite produces 9 passing tests.

## Local Development

### Install Dependencies

From the project root:

```
npm install
```

This installs Hardhat, Ethers, the testing libraries, and related tooling.

### Compile Contracts

```
npx hardhat compile
```

### Run Tests Locally

```
npx hardhat test
```

You should see all `NftCollection` tests passing.

## Docker Usage

The repository includes a `Dockerfile` so tests can be run in a reproducible container environment.

### Build the Docker Image

From the project root:

```
docker build -t nft-collection .
```

- Base image: `node:18-alpine`
- The image:
  - Copies `package*.json`
  - Installs npm dependencies
  - Copies the rest of the project
  - Compiles the contracts with Hardhat

### Run the Tests in Docker

```
docker run --rm nft-collection
```

- `--rm` removes the container when it exits.
- The container’s default command is `npx hardhat test`, so running the image executes the full test suite automatically.
- The output should again show 9 passing tests for `NftCollection`.

## Assumptions and Notes

- The contract is intentionally minimal and does not implement the full ERC‑721 standard (e.g., no interface detection via ERC‑165, no on‑receiver hook checks in `safeTransferFrom`).
- Minting requires the owner to choose unique `tokenId` values; duplicate IDs revert.
- The project is designed primarily as a learning and assessment scaffold, not as a production‑ready NFT implementation.
```