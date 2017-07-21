# 1 - Table of Contents

<!-- TOC depthFrom:1 depthTo:2 withLinks:1 updateOnSave:1 orderedList:0 -->

- [1 - Table of Contents](#1-table-of-contents)
- [2 - Introduction](#2-introduction)
	- [2.1 Audit Goals](#21-audit-goals)
	- [2.2 Source Code](#22-source-code)
	- [2.3 Documentation](#23-documentation)
	- [2.4 Dynamic Testing](#24-dynamic-testing)
- [3 - General Findings](#3-general-findings)
	- [3.1 Critical](#31-critical)
	- [3.2 Major](#32-major)
	- [3.3 Medium](#33-medium)
	- [3.4 Minor](#34-minor)
- [4 Detailed Solidity Review Findings](#4-detailed-solidity-review-findings)
- [5 Test Coverage Analysis](#5-test-coverage-analysis)
	- [5.1 General Discussion](#51-general-discussion)
- [Appendix - Description of Token Distribution](#description-token-distribution)
- [Appendix 1 - Audit Participants](#appendix-1-audit-participants)
- [Appendix 2 - Terminology](#appendix-2-terminology)
	- [A.2.1 Coverage](#a21-coverage)
	- [A.2.2 Severity](#a22-severity)
- [Appendix 3 - Framework Components and Concepts](#appendix-3-framework-components-and-concepts) //OPTIONAL
- [Appendix 4 - Audit Details](#appendix-4-audit-details)
	- [A.4.1 File List](#a41-file-list)
	- [A.4.2 Static Analysis of Project's Files](#a42-line-count)
	- [A.4.3 File Signatures](#a43-file-signatures)
- [Appendix 5 - Test Battery Results](#appendix-4-test-battery-results)

<!-- /TOC -->

# 2 - Introduction

From July 3 through July 21 of 2017, ConsenSys Diligence conducted an initial phase of a security
audit of the 0xProject's contract system. The findings of this preliminary audit are presented here in this document.

## 2.1 Audit Goals

### 2.1.1 Security

This audit focused on identifying security related issues within each
contract and within the system of contracts.

### 2.1.2 Sound Architecture

This audit evaluates the architecture of this system through the lens of
established smart contract best practices and general software best practices.

### 2.1.3 Code Correctness and Quality

This audit includes a full review of the contract source code.  The primary
areas of focus include:

* Correctness (does it do was it is supposed to do)
* Readability (How easily it can be read and understood)
* Sections of code with high complexity
* Identification of antipatterns
* Improving scalability
* Quantity and quality of test coverage


## 2.2 Source Code


The code being audited was from the [0xProject/contracts](https://github.com/0xProject/contracts/tree/frozen) repository.

The state of the source code at the time of the audit can be found under the commit hash `888d5a02573572240f4c55e03238be603c13c469`.

## 2.3 Documentation

The following documentation was available to the review team:

* The [0x Project Whitepaper](https://0xproject.com/pdfs/0x_white_paper.pdf)
* The [README](https://github.com/0xProject/contracts/blob/master/README.md) file for the [0xProject/contracts](https://github.com/0xProject/contracts/tree/frozen) repository.

## 2.4 Dynamic Testing

### Pre-existing tests

The pre-existing tests for [0xProject/contracts](https://github.com/0xProject/contracts/tree/frozen) repository were executed using the truffle framework, run against contracts deployed on a local instance of testrpc.

In order for the tests to succeed, the module `ethereumjs-testrpc` had to be uninstalled and reinstalled specifying version `3.0.2`.

```
$ npm uninstall -g ethereumjs-testrpc
$ npm install -g ethereumjs-testrpc@3.0.2
```

# 3 - General Findings

This section discusses general issues that apply to the contract (and test) code base. These issues are primarily related to architecture, security assumptions and other high level design decisions, and are essential to a thorough security review. Realizing that these decisions are made as part of a set of trade offs, the 0xProject team may decide not to take action on all of our findings. They should however clarify the rationale for such decisions.

The following Issues on Github:
* https://github.com/0xProject/contracts/issues/92
* https://github.com/0xProject/contracts/pull/96
* https://github.com/0xProject/contracts/issues/94
* https://github.com/0xProject/contracts/issues/89
* https://github.com/0xProject/contracts/issues/93
* https://github.com/0xProject/contracts/issues/77

The following Issues on Github that have been fixed:
* https://github.com/0xProject/contracts/issues/88
* https://github.com/0xProject/contracts/issues/84
* https://github.com/0xProject/contracts/issues/91
* https://github.com/0xProject/contracts/issues/80

* There is a lack of documentation, with many interactions and components of th system not covered at all in the white paper.  For example, see Appendix - Description of Token Distribution.  Furthermore, it may be preferrable for the system to be more codified and deterministic then being dependent on centralized actions such as https://github.com/0xProject/contracts/issues/75 where the timing is essentially arbitrary.


## 3.1 Critical

No bugs or security vulnerabilities were found to be directly exploitable, and thus critical.

## 3.2 Major

### 3.2.1 Reentrancy risk from malicious tokens

Calling an untrusted contract has risks which can be difficult to quantify given the dynamic and evolving nature of smart contracts. While no evidence of an exploit is currently found, one that we'd like to discuss is the Proxy.sol calling an untrusted contract's `transferFrom` (https://github.com/0xProject/contracts/blob/888d5a02573572240f4c55e03238be603c13c469/contracts/Proxy.sol#L101).  A malicious token contract could implement its `transferFrom` to reenter the Exchange contract, for example to `fillOrder`s or `cancelOrder`s.

The TokenRegistry.sol may alleviate risks from malicious tokens, but Exchange.sol does not reference it at all.  A possible way to alleviate risks from unknown or malicious tokens, is to require that an exchange only use "whitelisted" tokens by a token registry.

#### Recommendations

In Exchange.sol, `require` that tokens are registered in TokenRegistry.sol.  In TokenRegistry.sol, provide a lookup by address function (possibly by adding a `mapping(address=>bool)`): the function could be called `exists` and the idea is that Exchange.sol would then have `require(registry.exists(makerToken))`. Implement this recommendation in small steps and commits where each commit includes thorough tests. It is likely that each commit will have more test code: for example when adding an `exists` function to the registry, there would probably be tests for: 1) non-existence, 2) existence, 3) non-existence where a prior existing token was removed 4) updating an existing token...

## 3.3 Medium  

### 3.3.1 Makers "griefing" takers

"Griefing" attack of creating many orders is possible, allowing a maker to burn people's gas.  For example: a taker is "griefed" by a maker who's order is no longer valid since the maker tokens no longer exist. This is hard to defend against, as it requires constantly monitoring the maker's token allowance given to the Exchange, (and possibly also balance).

#### Recommendations

Provide tools, scripts, libraries to make it easy for people to identify orders which are no longer valid.

## 3.4 Minor  

### 3.4.1 Versioning of Exchange contract

It's not clear how an upgraded exchange contract will differentiate from this contract.

#### Recommendations

A version string in Exchange.sol may be useful.

# 4 Detailed Solidity Review Findings

## 4.1 <contract file name>

Source File: [`<contract file folder/contract file name`](<link to this file in repo>)

### 4.1.1 <issue title>

Severity: **<issue severity>**

<issue long description>

#### Recommendation

<recommendation to solve the issue>



# 5 Test Coverage Analysis

Testing is implemented using the Truffle Framework.

Automated measurement was done using [SolCover](https://github.com/JoinColony/solcover).

The quality of test coverage was also assessed by inspection of the code.

## 5.1 General Discussion

<general notes>


### 5.2 <contract name>

Test File: [`<test file folder/test file name`](<link to this file in repo>)

Coverage: <coverage>

#### Test Output

```
<test output>
```

#### Coverage Notes:

<coverage notes>

* Coverage Rating: **<rating of coverage>**

# Appendix - Description of Token Distribution

The token distribution is an aspect of the 0x system with little documentation. The following describes our understanding of it.

The TokenDistributionWithRegistry (TD) contract's purpose is to create a single massive order that will be filled by those wanting to obtain ZRX.  The TD is the public's first chance at obtaining ZRX.  The TD's single order will specify a makerToken of ZRX, and a takerToken of EthToken (ETH which has been tokenized as ERC-20).

The order is "point-to-point" because the taker is the TD itself.  This means that the order should not specify any makerFee, takerFee, feeRecipient.

The TD makes uses 2 variables isInitialized and isFinished rather than more "explicit" state transitions.

The TD is init() with an order on EXCHANGE_CONTRACT (EC) that is signed by the account that created the ZRX token.  And TD approves the PROXY_CONTRACT (PC) control over TD's EthTokens.

The order's expirationTimestampInSec acts as a time limit for the duration of the distribution.  Until that time limit, addresses that are registered may send ETH with fillOrderWithEth() to get ZRX tokens.  The core mechanism is in 3 steps.  
First, the caller's ETH is deposited into the takerToken contract.  This effectively converts the callers ETH into EthTokens.  
Second, the order is fully executed (fillOrKillOrder() as opposed to partially fillable) on the EC.  The account with the ZRX now has EthTokens, and TD has ZRX tokens.  
Third, the TD transfers the ZRX to the caller (msg.sender).
fillOrderWithEth() should not be called by arbitrary contracts that do not have a way of getting the ZRX tokens out.

The owners of TD set an ethCapPerAddress, and this limits how much ETH can be exchanged for ZRX by a particular caller.  Excess ETH is sent back to the caller.  Caller cumulative contributions are tracked.  The owners can set ethCapPerAddress to whatever value at any time.

Also, at any time, the owners can enable and disable the addresses that can call fillOrderWithEth().


# Appendix 1 - Audit Participants

Security audit was performed by ConsenSys team members <members>.

# Appendix 2 - Terminology

## A.2.1 Coverage

Measurement of the degree to which the source code is executed by the test suite.

### A.2.1.1 untested

No tests.


### A.2.1.2 low

The tests do not cover some set of non-trivial functionality.


### A.2.1.3 good

The tests cover all major functionality.


### A.2.1.4 excellent

The tests cover all code paths.


## A.2.2 Severity

Measurement of magnitude of an issue.


### A.2.2.1 minor

Minor issues are generally subjective in nature, or potentially deal with
topics like "best practices" or "readability".  Minor issues in general will
not indicate an actual problem or bug in code.

The maintainers should use their own judgement as to whether addressing these
issues improves the codebase.


### A.2.2.2 medium

Medium issues are generally objective in nature but do not represent actual
bugs or security problems.

These issues should be addressed unless there is a clear reason not to.


### A.2.2.3 major

Major issues will be things like bugs or security vulnerabilities.  These
issues may not be directly exploitable, or may require a certain condition to
arise in order to be exploited.

Left unaddressed these issues are highly likely to cause problems with the
operation of the contract or lead to a situation which allows the system to be
exploited in some way.


### A.2.2.4 critical

Critical issues are directly exploitable bugs or security vulnerabilities.

Left unaddressed these issues are highly likely or guaranteed to cause major
problems or potentially a full failure in the operations of the contract.


# Appendix 4 - Audit Details

## A.4.1 File List

The following source files were included in the audit.

https://github.com/0xProject/contracts/commit/888d5a02573572240f4c55e03238be603c13c469

* Exchange.sol
* MultiSigWalletWithTimeLock.sol
* MultiSigWalletWithTimeLockExceptRemoveAuthorizedAddress.sol
* Proxy.sol
* TokenDistributionWithRegistry.sol
* TokenRegistry.sol
* base/MultiSigWallet.sol
* base/Ownable.sol
* base/SafeMath.sol
* base/StandardToken.sol
* base/StandardTokenWithOverflowProtection.sol
* base/Token.sol
* tokens/DummyToken.sol
* tokens/EtherToken.sol
* tokens/Mintable.sol
* tokens/ZRXToken.sol

<notes about possibly obsolete or completely unneeded files go here>

## A.4.2 Static Analysis of Project's Files

### A.4.2.1 File Count

The number of files present in the project is:

```
21
```

NIX command used for the statistic:

```
find . -name '*.sol' | wc -l
```

### A.4.2.2 LOC Count

The number of LOC present in the project is:

```
     365 ./contracts/base/MultiSigWallet.sol
      27 ./contracts/base/Ownable.sol
      41 ./contracts/base/SafeMath.sol
      44 ./contracts/base/StandardToken.sol
      89 ./contracts/base/StandardTokenWithOverflowProtection.sol
      38 ./contracts/base/Token.sol
     588 ./contracts/Exchange.sol
      23 ./contracts/Migrations.sol
     132 ./contracts/MultiSigWalletWithTimeLock.sol
      64 ./contracts/MultiSigWalletWithTimeLockExceptRemoveAuthorizedAddress.sol
     116 ./contracts/Proxy.sol
     297 ./contracts/TokenDistributionWithRegistry.sol
     309 ./contracts/TokenRegistry.sol
      33 ./contracts/tokens/DummyToken.sol
      47 ./contracts/tokens/EtherToken.sol
      16 ./contracts/tokens/Mintable.sol
      15 ./contracts/tokens/ZRXToken.sol
    1676 ./node_modules/truffle/build/Assert.sol
      13 ./node_modules/truffle/build/SafeSend.sol
       7 ./node_modules/truffle/build/templates/Example.sol
      13 ./node_modules/truffle/build/templates/Test.sol
    3953 total
```

NIX command used for the statistic:

```
find . -name '*.sol' | xargs wc -l
```

### A.4.2.3 ABI Inspection

How many functions are there in the project? (please see _Notes_ below)

```
202
```

How many state-changing functions are there in the project?

```
85
```

NIX command used for the statistic:

```
# output the ABI to a file using solc
$ solc --abi contracts/*.sol > abi.json
$ solc --abi contracts/base/*.sol > abi_base.json

# how many functions are there? 
$ cat abi.json | grep -o \"type\":\"function\" | wc -l
$ cat abi_base.json | grep -o \"type\":\"function\" | wc -l

# how many functions are state changing?
$ cat abi.json | grep -o \"constant\":false | wc -l
$ cat abi_base.json | grep -o \"constant\":false | wc -l
```

_Note:_ the `tokens` folder could not be inspected because the compiler was not able to process the `import` statements correctly.

### A.4.2.3 External Call Count

How many external calls are there in the project?

```
contracts/Exchange.sol:521:        						return Proxy(PROXY_CONTRACT).transferFrom(token, from, to, value);
contracts/Exchange.sol:574:        						return Token(token).balanceOf(owner);
contracts/Exchange.sol:586:        						return Token(token).allowance(owner, PROXY_CONTRACT);
contracts/Migrations.sol:21:        					upgraded.setCompleted(last_completed_migration);
contracts/MultiSigWalletWithTimeLock.sol:113:        	if (tx.destination.call.value(tx.value)(tx.data))
contracts/MultiSigWalletWithTimeLockExceptRemoveAuthorizedAddress.sol:42:        if (tx.destination.call.value(tx.value)(tx.data))
contracts/Proxy.sol:62:        							authorities.push(target);
contracts/Proxy.sol:101:        						return Token(token).transferFrom(from, to, value);
contracts/TokenDistributionWithRegistry.sol:183:        uint remainingEth = safeSub(order.takerTokenAmount, exchange.getUnavailableTakerTokenAmount(order.orderHash));
contracts/TokenDistributionWithRegistry.sol:186:        ethToken.deposit.value(ethToFill)();
contracts/TokenDistributionWithRegistry.sol:199:        assert(protocolToken.transfer(msg.sender, filledProtocolToken));
contracts/TokenDistributionWithRegistry.sol:202:        assert(msg.sender.send(safeSub(msg.value, ethToFill)));
contracts/TokenDistributionWithRegistry.sol:218:        assert(Token(_token).approve(PROXY_CONTRACT, _allowance));
contracts/TokenRegistry.sol:109:        				tokenAddresses.push(_token);
contracts/base/MultiSigWallet.sol:127:        			owners.push(owner);
contracts/base/MultiSigWallet.sol:228:            		if (tx.destination.call.value(tx.value)(tx.data))
contracts/tokens/EtherToken.sol:45:        				assert(msg.sender.send(amount));
```

NIX command used for the statistic:

```
egrep '\.\w*\(.*\)' contracts/* -nr
```

## A.4.3 File Signatures

The SHA256 hash of each files at the time of the audit was as follows.

<link to repo including frozen commit ref>

```
$ shasum -a 256 *
3735bf38919eee108050160416df761c7daeaf51f599ef66711ea8dc870a83df  Exchange.sol
c6ab0ec0aa9228fd1860a459a4ce5182ff3f5bfb067bffed6790bf5490ee259f  Migrations.sol
21760701907a858e824aa426a970bbac0b1f0ebc92323450ba68788db9cb2c31  MultiSigWalletWithTimeLock.sol
9770531fc2cefd7eb4b4beb2aa7cb0e30eacedfb86d52b54123599fc66be7606  MultiSigWalletWithTimeLockExceptRemoveAuthorizedAddress.sol
c803f22bf706761bd2c6e5e2a748994af0c475a6a26a18d395b918e0101fe237  Proxy.sol
9851e89ecafee0977cf1aca0bac6ab26f190461a7ac31cea7ee0382651c90fb5  TokenDistributionWithRegistry.sol
e2396ce460d77b1bfbb0564d8de30ea64e33f67a2ba0346ba4b46de9acb338c8  TokenRegistry.sol

$ shasum -a 256 tokens/*
7f8ecf84856c8d7a19cecc46dfd83c4caa9a69fe6cad76cf1b92653a74314b52  tokens/DummyToken.sol
45562f8dc0803d71d54e3d425092f206114563e6da4e14fda2ba3fadde86b594  tokens/EtherToken.sol
26c2377b293b30f9e21716d00b663141af5af47e67f06c5c8a33ac40f6ecd878  tokens/Mintable.sol
8d27f242c7797d0fa4b47cf924346c3f21c86d68728826cab7965be8b37de85f  tokens/ZRXToken.sol

$ shasum -a 256 base/*
9a34b67d72394a5ce5f1c67839df8e5cbf499ae61396a455293123cb010977d1  base/MultiSigWallet.sol
b3e362b53609f0b6efc4f00e5215d85e8e50db924752988704023ecf220af3f7  base/Ownable.sol
4f162f2481ce69be378ff44777be363aca50e96159c1fa84ff786974ceb34966  base/SafeMath.sol
165fc791ffe0ec3faa8e0eb3b1dc995650cfdf4d3c19bf5a6f0691c7a6540ea9  base/StandardToken.sol
c59b967d6f5c2f3f3b66ffe5a4ed26812cb57aea13f1b9ba087f44bcd79a31f0  base/StandardTokenWithOverflowProtection.sol
b3c224de95d004db90477fc9034c4e68afcc4679c93dfa9da3003bd44e0fe471  base/Token.sol
```
