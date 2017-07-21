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

From <start date [month + day]> through <finish date [month + day]> of 2017, ConsenSys Diligence conducted an security
audit of the 0xProject's contract system. The findings of this audit are presented here in this document.

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


The code being audited was from the [<repository name>](<repository link>).

The state of the source code at the time of the audit can be found under the commit hash `<commit hash>`.

## 2.3 Documentation

The following documentation was available to the review team:

* The [<whitepaper name & release date>](<link to respective whitepaper version>)
* The [README](https://github.com/uport-project/uport-proxy/blob/5979d3f121b5b89e58d6712d442f36750d8e37fd/README.md) file for the <project repo name> repository
* <Presentations slides and diagrams>
* <Functional Specification>

## 2.4 Dynamic Testing

### Pre-existing tests

The pre-existing tests for https://github.com/uport-project/uport-proxy/ were executed using the truffle framework, run against contracts deployed on a local instance of testrpc.  There were no pre-existing tests available for https://github.com/uport-project/uport-registry/.

Test results of the pre-existing test battery are available in Appendix 5.

### Additional testing //OPTIONAL

<possible additions to the test suite go here>



# 3 - General Findings

This section discusses general issues that apply to the contract (and test) code base. These issues are primarily related to architecture, security assumptions and other high level design decisions, and are essential to a thorough security review. Realizing that these decisions are made as part of a set of trade offs, the <project name> team may decide not to take action on all of our findings. They should however clarify the rationale for such decisions.

## 3.1 Critical

No bugs or security vulnerabilities were found to be directly exploitable, and thus critical.

## 3.2 Major

### 3.2.1 <issue title>

<issue long description>

#### Recommendations

<recommendation to solve the issue>

## 3.3 Medium  

### 3.3.1 <issue title>

<issue long description>

#### Recommendations

<recommendation to solve the issue>

## 3.4 Minor  

### 3.4.1 <issue title>

<issue long description>

#### Recommendations

<recommendation to solve the issue>

# 4 Detailed Solidity Review Findings

## 4.1 <contract file name>

Source File: [`<contract file folder/contract file name`](<link to this file in repo>)

### 4.1.1 <issue title>

Severity: **<issue severity>**

<issue long description>

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

### A.4.2.1 File Count

The number of files present in the project is:

```
<output of the command below>
```

NIX command used for the statistic:

```
find . -name '*.sol' | wc -l
```

### A.4.2.2 LOC Count

The number of LOC present in the project is:

```
<output of the command below>
```

NIX command used for the statistic:

```
find . -name '*.sol' | xargs wc -l
```

### A.4.2.3 ABI Inspection

How many functions are there in the project?

```
<output of the command below>
```

How many state-changing functions are there in the project?

```
<output of the command below>
```

NIX command used for the statistic:

```
# output the ABI to a file using solc
$ solc —abi contracts/*.sol > abi.json

# how many functions are there? 
$  cat abis.json | grep -o \"type\":\"function\" | wc -l

# how many functions are state changing?
$ cat abis.json | grep -o \"constant\":false | wc -l
```

### A.4.2.3 External Call Count

How many external calls are there in the project?

```
<output of the command below>
```

NIX command used for the statistic:

```
egrep '\.\w*\(.*\)' contracts/* --colour=auto -nr
```

## A.4.3 File Signatures

The SHA256 hash of each files at the time of the audit was as follows.

<link to repo including frozen commit ref>

```
$ shasum -a 256 *
<sha256 hash> <file name>
```


# Appendix 5 - Test Battery Results

In order for the tests to succeed, <explain possible steps needed to make tests run>.

```
<paste commands to run in terminal for above to be possible>
```

Results from the pre-existing test battery are provided here for reference.

```
<paste terminal output here>
```
