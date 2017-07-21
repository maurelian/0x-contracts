## General Issues and Comments

* lack of documentation
* all functions should be explicitly labelled internal or public. There is inconsistent use of the `public` keyword on public functions
* "Griefing" attack of creating many orders is possible, allowing a maker to burn people's gas. This is hard to defend against, as it requires constantly monitoring the maker's token allowance given to the Exchange, (and possibly also balance).
* Is checking againt `address(0)` useful? I don't think so. There are an almost infinite number of ways to throw tokens into a blackhole, no reason to spend computation power on this one in particular.


## Contracts

### Exchange.sol

* Replay protection is provided by the filled and cancelled mappings (not really an issue...)
* Versioning: it's not clear how an upgraded exchange contract will differentiate from this contract. A version string would be useful, either in this contract, or the proxy.
* Timestamps are being used. I don't think I hold a strong objection to this, perhaps deserves some discussion.
* all functions should be explicitly labelled internal or public...
* the rounding in `isRoundingError` needs consideration for
* the exchange does not reference the registry at all
* without a registry to 'whitelist' approved coins, there is a risk of exploits by a malicious token
* the `makerFee` and `takerFee` fields are not included in the white paper for point to point orders. It's not clear if this is intentional.
* The `makerFee` value is a uint, making it impossible to give negative fees, which is sometimes useful for incentivizing liquidity.

### TokenDistributionWithRegistry.sol

* The frozen branch had no migrations for this contract. They seem to have been added to the master branch however.
* Despite the file name, there is no reference to the registry contract at all.
* There is no `require` statement to ensure there are no fees, and no `feeRecipient` on the order. This seems unlikely, but does require extra verification of the published code, or simple trust that no fee has been specified. This is particularly relevant given that the `TokenDistributionWithRegistry` contract uses the Exchange mechanism, but inserts itself as the taker, and then forwards the proceeds to the caller of `fillOrderWithEth()`.

* We note that the contract is using up 3 storage slots which could be avoided: https://github.com/0xProject/contracts/blob/888d5a02573572240f4c55e03238be603c13c469/contracts/TokenDistributionWithRegistry.sol#L35-L37  This is effectively a one-time cost instead of a recurring cost, so no dangers related to increasing costs.

### TokenRegistry.sol








### MultiSigWalletWithTimeLock.sol

*  In the contract, a transaction has a confirmation time if and only if it is confirmed by the required number of owners. The `confirmationTimeNotSet` and `confirmationTimeSet` modifiers are named according to their design, rather than their purpose, which is to guard against calls to `confirmTransaction()`, and `revokeConfirmation()`. The `isConfirmed()` function could be reused to create a pair of modifiers more accurately named `checkConfirmed()` and `checkNotConfirmed()`. These names would be more explicit and thus readable for future reviewers.



### MultiSigWalletWithTimeLockExceptRemoveAuthorizedAddress.sol

* Same note as above about `confirmationTimeSet` modifier


### tokens/ZRXToken.sol

* Constructor is misnamed as `ProtocolToken()`. https://github.com/0xProject/contracts/issues/88 was fixed, but the fix didn't include a test.


## /// Items we'll likely remove before sending

### SafeMath

* I had a comment about untested functions, and safeDiv being unnecessary, but I don't think either really needs to be included.
