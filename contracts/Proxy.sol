/*

  Copyright 2017 ZeroEx Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
pragma solidity ^0.4.11;

// NOTE: `MultiSigWalletWithTimeLock` is the owner of this contract according to 5_transfer_ownership deployment script
import "./base/Token.sol";
import "./base/Ownable.sol";

/// @title Proxy - Transfers tokens on behalf of contracts that have been approved via decentralized governance.
/// @author Amir Bandeali - <amir@0xProject.com>, Will Warren - <will@0xProject.com>
contract Proxy is Ownable {

    /// @dev Only authorized addresses can invoke functions with this modifier.
    modifier onlyAuthorized {
        require(authorized[msg.sender]); // NOTE: require(false) is a REVERT (0xFD)
        _;
    }

    // NOTE: onlyAuthorized could be replace with a call to targetAuthorized(msg.sender)
    // it should then be renamed to something like `isAuthorized`
    // the readability is probably justified though. 
    modifier targetAuthorized(address target) {
        require(authorized[target]);
        _;
    }

    modifier targetNotAuthorized(address target) {
        require(!authorized[target]);
        _;
    }

    mapping (address => bool) public authorized;
    address[] public authorities;

    event LogAuthorizedAddressAdded(address indexed target, address indexed caller);
    event LogAuthorizedAddressRemoved(address indexed target, address indexed caller);

    /*
     * Public functions
     */

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    /// @return Success of authorization.
    function addAuthorizedAddress(address target)
        public // <- add
        onlyOwner
        targetNotAuthorized(target)
        returns (bool success)
    {
        authorized[target] = true;
        authorities.push(target);
        LogAuthorizedAddressAdded(target, msg.sender);
        return true;
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @return Success of deauthorization.
    function removeAuthorizedAddress(address target)
        onlyOwner
        targetAuthorized(target)
        returns (bool success)
    {
        delete authorized[target];
        //NOTE: remove algorithm scrambles the chronological order
        for (uint i = 0; i < authorities.length; i++) {
            if (authorities[i] == target) {
                authorities[i] = authorities[authorities.length - 1];
                authorities.length -= 1;
                break;
            }
        }
        LogAuthorizedAddressRemoved(target, msg.sender);
        return true;
    }

    /// @dev Calls into ERC20 Token contract, invoking transferFrom.
    /// @param token Address of token to transfer.
    /// @param from Address to transfer token from.
    /// @param to Address to transfer token to.
    /// @param value Amount of token to transfer.
    /// @return Success of transfer.
    function transferFrom(
        address token,
        address from,
        address to,
        uint value)
        onlyAuthorized
        returns (bool success)
    {
        //NOTE: This makes the owners have to be really careful with future exchange designs. ALWAYS CHECK FOR REENTRANCY BUGS.
        //      Optimaly don't have a function called `transferFrom()` in Exchange(.sol)-like contracts and make sure it doesn't
        //      implement a fallback function as well.
        return Token(token).transferFrom(from, to, value);
    }

    /*
     * Public constant functions
     */

    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses()
        constant
        returns (address[])
    {
        return authorities;
    }
}
