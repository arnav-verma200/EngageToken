# EngageToken – Social Media Engagement Reward System

**Contract Address:** 0x4DF75f6B973D15AD1A58Eacea346baF0EAc95024
**Network:** Flow EVM Testnet

## Overview

EngageToken (ENG) is a simple ERC-20–like token built to reward users based on social media engagement.
Trusted verifiers can mint tokens for users depending on their engagement (likes, comments, shares).

---

## Key Features

* ERC-20 compatible functions (`transfer`, `approve`, `transferFrom`)
* Owner-controlled access
* Verifier system to issue tokens for engagement
* Double-mint protection using `claimId`
* Adjustable reward multiplier
* No imports or constructor – fully self-contained

---

## Token Details

| Property | Value                                      |
| -------- | ------------------------------------------ |
| Name     | EngageToken                                |
| Symbol   | ENG                                        |
| Decimals | 18                                         |
| Network  | Flow EVM Testnet                           |
| Contract | 0x4DF75f6B973D15AD1A58Eacea346baF0EAc95024 |

---

## How It Works

1. **Initialize Owner**
   Call `init()` once to set the owner.

2. **Add Verifier**
   Owner calls `addVerifier(address)` to authorize verifiers.

3. **Issue Tokens**
   Verifier calls `issueForEngagement(to, likes, comments, shares, claimId)`
   Example:

   ```
   issueForEngagement(0xUser, 120, 40, 20, "claim123");
   ```

4. **Set Multiplier**
   Owner calls `setMultiplier(value)` to adjust reward scaling.

---

## Main Functions

### Read Functions

* `name()` – Returns token name
* `symbol()` – Returns symbol
* `decimals()` – Returns decimals
* `totalSupply()` – Total tokens minted
* `balanceOf(address)` – Balance of a user
* `isVerifier(address)` – Check if verifier
* `isClaimUsed(verifier, claimId)` – Check if claim already used

### Write Functions

* `init()` – Initialize contract (only once)
* `addVerifier(address)` – Add verifier
* `removeVerifier(address)` – Remove verifier
* `setMultiplier(uint256)` – Change reward multiplier
* `burnFrom(address, uint256)` – Burn tokens from address

---

## Deployment Info

* Network: Flow EVM Testnet
* Compiler: Solidity ^0.8.19
* License: MIT
* No external imports or constructor used

---

## Notes

* Each `claimId` is unique and can’t be reused.
* Verifiers are responsible for calculating engagement off-chain.
* This version is for testing and demonstration purposes only.

---

