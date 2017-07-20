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
	- [4.1 UportRegistry.sol](#41-uportregistrysol)
	- [4.2 IdentityFactory.sol](#42-identityfactorysol)
	- [4.3 IdentityFactoryWithRecoveryKey.sol](#43-identityfactorywithrecoverykeysol)
	- [4.4 Owned](#44-owned)
	- [4.5 Proxy.sol](#45-proxysol)
	- [4.6 RecoverableController](#46-recoverablecontroller)
	- [4.6 RecoveryQuorum](#46-recoveryquorum)
- [5 Test Coverage Analysis](#5-test-coverage-analysis)
	- [5.1 General Discussion](#51-general-discussion)
- [Appendix 1 - Audit Participants](#appendix-1-audit-participants)
- [Appendix 2 - Terminology](#appendix-2-terminology)
	- [A.2.1 Coverage](#a21-coverage)
	- [A.2.2 Severity](#a22-severity)
- [Appendix 3 - Framework Components and Concepts](#appendix-3-framework-components-and-concepts)
	- [A.3.1 Proxy](#a31-proxy)
	- [A.3.2 Registry](#a32-registry)
- [Appendix 4 - Audit Details](#appendix-4-audit-details)
	- [A.4.1 File List](#a41-file-list)
	- [A.4.2 Line Count](#a42-line-count)
	- [A.4.3 File Signatures](#a43-file-signatures)
- [Appendix 4 - Test Battery Results](#appendix-4-test-battery-results)

<!-- /TOC -->

# 2 - Introduction

From March 4th through April 6th of 2016, ConsenSys conducted an internal security
audit of the uPort framework authored by the uPort team within ConsenSys.  The findings
of this audit are presented here in this document.

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
* Quantity and quality of test coverage



## 2.2 Source Code

The code being audited was from the [**uport-proxy** repository](https://github.com/uport-project/uport-proxy/tree/5979d3f121b5b89e58d6712d442f36750d8e37fd) under the **uport-project** github account.

https://github.com/uport-project/uport-proxy

The state of the source code at the time of the audit can be found under the commit hash `5979d3f121b5b89e58d6712d442f36750d8e37fd` which was tagged as `Merge branch 'recoverykey'`.

At a later point, an additional [**uport-registry** repository](https://github.com/uport-project/uport-registry/tree/2f64fc0410d5d3946b71d47378fada57d919c8be) was added to the review scope, again from the **uport-project** github account.

The state of this source code at the time of the audit can be found under the commit hash `2f64fc0410d5d3946b71d47378fada57d919c8be`.

Further details may be found in Appendix 4.

## 2.3 Documentation

The following documentation was available to the review team:

* The [February 2017 whitepaper](http://whitepaper.uport.me/uPort_whitepaper_DRAFT20170221.pdf)
	* This documentation was not originally provided to the review team, who initially were working from the [October 2016 whitepaper](http://whitepaper.uport.me/uPort_whitepaper_DRAFT20161020.pdf).
* The  [README](https://github.com/uport-project/uport-proxy/blob/5979d3f121b5b89e58d6712d442f36750d8e37fd/README.md) file for the Proxy repository
	* The Proxy README also contained a link to "[Proxy contracts and metatransactions with applications](https://docs.google.com/document/d/1fq0B0T5d0uTJM9rwcT0u2UUCPWzUSYx7GSvZidWVghI)".
* The [README](https://github.com/uport-project/uport-registry/tree/2f64fc0410d5d3946b71d47378fada57d919c8be/README.md) file for the Registry repository

## 2.4 Dynamic Testing

### Pre-existing tests

The pre-existing tests for https://github.com/uport-project/uport-proxy/ were executed using the truffle framework, run against contracts deployed on a local instance of testrpc.  There were no pre-existing tests available for https://github.com/uport-project/uport-registry/.

Test results of the pre-existing test battery are available in Appendix 5.

### Additional testing

In addition to the Uport teams tests, the review team also wrote additional tests in order to explore possible attack vectors, and better understand the contract interactions.

# 3 - General Findings
////////
//Is this section really needed?
//I prefer findings by file, seem easier to navigate
////////

This section discusses general issues that apply to the contract (and test) code base. These issues are primarily related to architecture, security assumptions and other high level design decisions, and are essential to a thorough security review. Realizing that these decisions are made as part of a set of trade offs, the uPort team may decide not to take action on all of our findings. They should however clarify the rationale for such decisions.

## 3.1 Critical

No bugs or security vulnerabilities were found to be directly exploitable, and thus critical.

## 3.2 Major

### 3.2.1 Proxy funds at risk given user key compromise

The security model assumes that the user key can never be compromised, only lost.  If this assumption is violated then the device of this Smart Contract System (SCS) is completely compromised.

In the event of a key compromise, such as could result from user-protection override on a stolen device, all user funds held in the proxy are immediately at risk. Identity theft and impersonation also become temporarily possible.

#### Recommendations

1. Consider improving the security model by removing of the assumption that the user key can never be compromised but only lost.

	For example, the `RecoverableController.forward()` function could restrict withdrawal of funds a maximum amount per time period. This maximum could be set by uPort upon creation, and/or modified by the user afterwards. The benefits of such changes should be weighed against the cost of adding complexity to the contract system.

	An alternative approach, which would avoid additional complexity could be to encourage users to store funds in a multi-sig wallet in which the proxy contract is one of several owners.

2. The following features can be added to the mobile application. These features neither improve the contract security model, nor add complexity to the contract system.  Instead, these mobile application features directly help uPort meet the assumptions put in place by the contract security model.

	* uPort application user password
	* password required again at uPort contract operation
	* challenge/response requiring user to supply an application-known secret at contract operation
	* NOTE: most 2FA solutions are rendered invalid if a device is compromised

 3. The following restrictions should also be made clear to users and developers:

	* uPort security model is only supported via our mobile application library
	* uPort contracts are not to be used outside of this environment
	* jailbroken iOS devices render uPort application security model insecure
	* allowing external application installation on Android (typical developer setting) renders model insecure

4. The following attack vectors should be completely explored from a white hat perspective:
	* key management of iOS and Android mobile applications given full disassembly manipulation capabilities
	* application placed onto stolen device (Android in development mode, jailbroken iOS) to extract user key


### 3.2.2 The `userKey` appears is extremely powerful

Severity: **Medium**

The `userKey` has sole access to call on the following functions

* `forward`
* `signRecoveryChange()`
* `signControllerChange()`
* `signUserKeyChange()`

The design of the 3 `sign__Change()` functions make it such that an attacker who gains access to the userKey can have full ownership of the proxy contract as soon as the `longTimeLock` period has passed (suggested is 3 days).

Thus, if the userKey is stolen AND the rightful owner no longer has access to it (ie. stolen phone), the only way to prevent a complete and permanent theft of the proxy contract is for a majority of delegates to agree on a new `proposedUserKey`  before the end of the `longTimeLock` period.

Even if this is done in time, the new `userKey` will still need to pass `0x0` before the end of the `longTimeLock` period. This allows little margin for error.

An implicit design assumption is that uPort will be able to coordinate action by a sufficient number of delegates to return the Proxy its rightful owner within the `longTimeLock` period, and that the owner could cancel any pending changes from calls the attacker had made to `signRecoveryChange()`, `signControllerChange()`, `signUserKeyChange()`.

#### Recommendation

uPort's recovery features represent significant improvement over the status quo of complete dependence on the secure ownership of a single private key, these features also encourage a different set of user behaviors and expectations.

No changes are recommended to the contract system here, but we wish to underscore the importance of the surrounding systems. Particularly important is the security of mobile applications, and optimal communication with delegates to ensure the correct required actions are taken in a timely manner.

### 3.2.3 The `recoveryKey` is extremely powerful

Severity: **Medium**

Similar to the `userKey`, the `recoveryKey` has sole access to call on the following functions:
	    - `changeRecoveryFromRecovery()`
	    - `changeUserKeyFromRecovery()`

Thus, a majority of delegates cannot be stopped from changing the `userkey`. The advantage is that `userkey` loss/hack appears to always be stoppable by delegates if they act within the longTimeLock.

The disadvantage is that a majority of malicious or compromised delegates cannot be stopped from "destroying" an identity by forcibly changing the `userkey`.

According to the `IdentityFactoryWithRecoveryKey.sol` contract, there is an expectation for use cases in which this key would not be controlled by a quorum. In that case, the `recoveryKey` is even more powerful than the `userKey`, and would make it possible to steal the proxy contract permanently and immediately. (It is now our understanding that the `recoveryKey` is never intended to be a non-contract account, and this factory contract will not be used.)

#### Recommendations

Take reasonable steps to ensure that a `recoveryKey` never belongs to a non-contract account.

Carefully design the guidance provided to the user related to add delegate accounts. Possible configurations to prevent account take over by malicious delegates include:

* Providing the user with their own delegate key. It could be printed and stored offline as a mnemonic.
* The percentage of delegate signatures required could be effectively increased to greater than 50% +1, by adding “non-existent keys” such as `0x0000...` to the delegate list.

## 3.3 Medium

### 3.3.1 Lack of documentation

The review was made more difficult by a lack of documentation clarifying the reasoning and assumptions made during the design process.

#### Recommendation

Along with the whitepaper, mobile security design documentation should be created for both the Android and iOS applications. These documents should outline software libaries, and operating system specific technologies relied upon for keychain management and security.

### 3.3.2 Use an exact and consistent version of Solidity compiler

Contracts in the proxy repository currently specify any compiler version above 0.4.4, below 0.5.0.

		pragma solidity ^0.4.4;

In addition, the registry contract uses a different pragma from the other files. All files should use the same compiler version unless there is a clear reason, and comments or documentation explaining why.

#### Recommendation

Fix on a specific version, at minimum 0.4.9, as versions up to 0.4.10 include many bug fixes.


### 3.3.3 Protect users against known paths to "bricking" the contract system

There are many ways in which the contract system could be misused, either by user error, or as the result of social engineering.

Protecting the user against all known ways they can change their setup (with controller/quorum/userKey, etc) is not possible, and some of this protection is left to the front-end. However, there are scenarios where it is cheap in terms of gas, and obvious wrong choices that the smart SCS can enforce.

For example, changing the Proxy's owner to itself should could be prevented by slightly modifying the transfer function to:

```
function transfer(address _owner) onlyOwner {
	if (_owner == address(this)){
    	owner = _owner;
	}
}
```

The rest of the Ethereum ecosystem is unknown, but the smart contracts have relative knowledge about its own threat model, and it would be cheap to implement.

### 3.3.4 Prevent invalid contract inputs to the constructors

Severity: **Medium**

There are many scenarios where intentionally incorrect inputs can lead to complete "bricking" the contract system.

This mostly occurs during constructors that don't have any balances or checks. Notably the recovery quorum definitely could result in screw ups. Or examples where contracts reference other contracts that it shouldn't really be capable of doing. eg: doing a transfer on the proxy to the proxy itself. Which means that the "controller" is now the proxy as well. This bricks the identity. At minimum I would recommended that smart contracts should at least protect from obvious bricks, like setting ownership to itself.

#### Recommendation:

In general, this is a subjective choice: should the contract protect the users to some extent, or should the front-end do this?

### 3.3.6 Test procedures restricted to `testrpc`

The `truffle.js` configuration files contains only the default settings for the `development` network, which suggests that the test suite has only been run on `testrpc`.

#### Recommendation

For the sake of completeness, also run tests on the Ropsten or Kovan test networks.

### 3.3.5 Absence of assertion guards and emergency circuit breakers

There are no [assert guards](https://github.com/ConsenSys/smart-contract-best-practices/blob/b485067ece502e683b80b9a584e459e1096bf8cc/README.md#assert-guards) in the contract system to automatically identify when a contract is in an invalid state.

Similarly there is no ability to manually halt the Controller or Proxy or Quorum operations upon compromise via a [circuit breaker](https://github.com/ConsenSys/smart-contract-best-practices/#circuit-breakers-pause-contract-functionality).

#### Recommendation

We recognize that such additional fail safe features would come at the cost of added complexity.  Consider implementing a circuit breaker type fail safe, or document the rationale for not doing so.

## 3.4 Minor

### 3.4.1 On-chain visibility of state variables

All variables in the contract system have been made `public`. For example in [RecoverableController.sol](https://github.com/uport-project/uport-proxy/blob/5979d3f121b5b89e58d6712d442f36750d8e37fd/contracts/RecoverableController.sol#L5-L20):

```
contract RecoverableController {
    uint    public version;
    Proxy   public proxy;

    address public userKey;
    address public proposedUserKey;
    uint    public proposedUserKeyPendingUntil;

    address public recoveryKey;
    address public proposedRecoveryKey;
    uint    public proposedRecoveryKeyPendingUntil;

    address public proposedController;
    uint    public proposedControllerPendingUntil;

    uint    public shortTimeLock;// use 900 for 15 minutes
    uint    public longTimeLock; // use 259200 for 3 days
```

There are no known risks to this, however obscuring state variables is a more conservative approach.

#### Recommendation

Provide documentation



//I'm only done up to here really
//Above are just ideas until now

# 4 Detailed Solidity Review Findings

## 4.1 <contract file name>

Source File: [`<contract file folder/contract file name`](<link to this file in repo>)

### 4.1.1 <issue name>

Severity: **<issue severity>**

<issue description>

#### Recommendation

<recommendation to solve the issue>



# 5 Test Coverage Analysis

Testing is implemented using the <framework name>.

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


//# Appendix 3 - Framework Components and Concepts
// don't think this is needed


# Appendix 4 - Audit Details

## A.4.1 File List

The following source files were included in the audit.

<link to repo including frozen commit ref>

* <file name>
* <file name 2>

<notes about possibly obsolete or completely unneeded files go here>

## A.4.2 Static Analysis of Project's Files

<paste output from John's command line greps>

## A.4.3 File Signatures

The SHA256 hash of each files at the time of the audit was as follows.

<link to repo including frozen commit ref>

```
$ shasum -a 256 *
<sha256 hash> <file name>
```


# Appendix 4 - Test Battery Results

In order for the tests to succeed, <explain possible steps needed to make tests run>.

```
<paste commands to run in terminal for above to be possible>
```

Results from the pre-existing test battery are provided here for reference.

```
<paste terminal output here>
```
