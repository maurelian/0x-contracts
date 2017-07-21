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

### TokenDistributionWithRegistry.sol


### TokenRegistry.sol


### MultiSigWalletWithTimeLock.sol


### MultiSigWalletWithTimeLockExceptRemoveAuthorizedAddress.sol


### tokens/ZRXToken.sol

* Constructor is misnamed as `ProtocolToken()`


## /// Items we'll likely remove before sending

### SafeMath 

* I had a comment about untested functions, and safeDiv being unnecessary, but I don't think either really needs to be included.
