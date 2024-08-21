# ERC-7540 Reference Implementations • [![CI](https://github.com/transmissions11/foundry-template/actions/workflows/tests.yml/badge.svg)](https://github.com/transmissions11/foundry-template/actions/workflows/tests.yml)

Reference implementations for [ERC-7540](https://eips.ethereum.org/EIPS/eip-7540).

[**Controlled Async Deposits**](https://github.com/ERC4626-Alliance/ERC-7540-Reference/blob/main/src/ControlledAsyncDeposits.sol) reference:
  - yield for the underlying asset is assumed to be transferred directly into the vault by some arbitrary mechanism
  - async deposits are subject to approval by an owner account
  - users can only deposit the maximum amount.
  To allow partial claims, the deposit and mint functions would need to allow for pro rata claims.
  Conversions between claimable assets/shares should be checked for rounding safety.

