# ERC-7540 Reference Implementations • [![CI](https://github.com/ERC4626-Alliance/ERC-7540-Reference/actions/workflows/tests.yml/badge.svg)](https://github.com/ERC4626-Alliance/ERC-7540-Reference/actions/workflows/tests.yml)

Reference implementations for [ERC-7540](https://eips.ethereum.org/EIPS/eip-7540).

This code is unaudited.

#### Controlled Async Deposit ([code](https://github.com/ERC4626-Alliance/ERC-7540-Reference/blob/main/src/ControlledAsyncDeposit.sol))
- Deposits are asynchronous and subject to fulfillment by an owner account
- Redemptions are synchronous (standard ERC4626)
  
#### Controlled Async Redeem ([code](https://github.com/ERC4626-Alliance/ERC-7540-Reference/blob/main/src/ControlledAsyncRedeem.sol))
- Deposits are synchronous (standard ERC4626)
- Redemptions are asynchronous and subject to fulfillment by an owner account
  
#### Fully Async Vault ([code](https://github.com/ERC4626-Alliance/ERC-7540-Reference/blob/main/src/FullyAsyncVault.sol))
Inherits from Controlled Async Deposit and Controlled Async Redeem

- Both deposits and redemptions are asynchronous and subject to fulfillment by an owner account
  
#### Timelocked Async Redeem ([code](https://github.com/ERC4626-Alliance/ERC-7540-Reference/blob/main/src/TimelockedAsyncRedeem.sol))
- Deposits are synchronous (standard ERC4626)
- Redemptions are asynchronous and subject to a 3 day delay
- New redemptions restart the 3 day delay even if the prior redemption is claimable.
- The redemption exchange rate is locked in immediately upon request.

## License
This codebase is licensed under [MIT license](https://github.com/ERC4626-Alliance/ERC-7540-Reference/blob/main/LICENSE).
