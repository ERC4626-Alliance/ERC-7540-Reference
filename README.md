# ERC-7540 Reference Implementations • [![CI](https://github.com/ERC4626-Alliance/ERC-7540-Reference/actions/workflows/tests.yml/badge.svg)](https://github.com/ERC4626-Alliance/ERC-7540-Reference/actions/workflows/tests.yml)

Reference implementations for [ERC-7540](https://eips.ethereum.org/EIPS/eip-7540).

This code is unaudited.

#### Controlled Async Deposits ([code](https://github.com/ERC4626-Alliance/ERC-7540-Reference/blob/main/src/ControlledAsyncDeposits.sol))
- Async deposits are subject to approval by an owner account
- Users can only deposit the maximum amount.
  
#### Timelocked Async Withdrawals ([code](https://github.com/ERC4626-Alliance/ERC-7540-Reference/blob/main/src/TimelockedAsyncWithdrawals.sol))
- Async redemptions are subject to a 3 day delay
- New redemptions restart the 3 day delay even if the prior redemption is claimable.
- The redemption exchange rate is locked in immediately upon request.
- Users can only redeem the maximum amount.

## License
This codebase is licensed under [MIT license](https://github.com/ERC4626-Alliance/ERC-7540-Reference/blob/main/LICENSE).
