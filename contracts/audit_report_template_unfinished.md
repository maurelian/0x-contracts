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

From July DATE_HERE through DATE_HERE of 2017, ConsenSys Diligence conducted an security
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
* Quantity and quality of test coverage



## 2.2 Source Code

The code being audited was from the [0xProject/contracts repository](https://github.com/0xProject/contracts/commit/888d5a02573572240f4c55e03238be603c13c469).

The state of the source code at the time of the audit can be found under the commit hash `5979d3f121b5b89e58d6712d442f36750d8e37fd`.

## 2.3 Documentation

The following documentation was available to the review team:

* Whitepaper... 
* Presentations slides and diagrams...
* 

## 2.4 Dynamic Testing

### Pre-existing tests

The pre-existing tests for https://github.com/uport-project/uport-proxy/ were executed using the truffle framework, run against contracts deployed on a local instance of testrpc.  There were no pre-existing tests available for https://github.com/uport-project/uport-registry/.

Test results of the pre-existing test battery are available in Appendix 5.

### Additional testing

////////
//Will we be writing any additional tests? I would only see a need for it if we thought we had an 
//exploit to show.
//although, I would like to slightly modify some of their tests to get more data about gas usage.
////////


# 3 - General Findings
////////
//Is this section really needed?
//I prefer findings by file, seem easier to navigate
////////

This section discusses general issues that apply to the contract (and test) code base. These issues are primarily related to architecture, security assumptions and other high level design decisions, and are essential to a thorough security review. Realizing that these decisions are made as part of a set of trade offs, the uPort team may decide not to take action on all of our findings. They should however clarify the rationale for such decisions.

## 3.1 Critical

No bugs or security vulnerabilities were found to be directly exploitable, and thus critical.

## 3.2 Major

### 3.2.1 {{Issue description}}

Lorem ipsum... 

#### Recommendations

placeholder text... 

## 3.3 Medium  

.....

## 3.4 Minor  

......



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
