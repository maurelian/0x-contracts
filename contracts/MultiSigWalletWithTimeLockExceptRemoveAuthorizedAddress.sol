pragma solidity ^0.4.11;

import "./MultiSigWalletWithTimeLock.sol";

// everything except `removeAuthorizedAddress()` is time locked

contract MultiSigWalletWithTimeLockExceptRemoveAuthorizedAddress is MultiSigWalletWithTimeLock {

    address public PROXY_CONTRACT;

    modifier validRemoveAuthorizedAddressTx(uint transactionId) {
        Transaction tx = transactions[transactionId];
        assert(tx.destination == PROXY_CONTRACT);
        //NOTE: why assert here if the function (below) itself already asserts during its execution?
        //assert(isFunctionRemoveAuthorizedAddress(tx.data));
        assert(bytes4FromBytes(tx.data) == bytes4(sha3("removeAuthorizedAddress(address)")));
        _;
    }

    /// @dev Contract constructor sets initial owners, required number of confirmations, time lock, and proxy address.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _secondsTimeLocked Duration needed after a transaction is confirmed and before it becomes executable, in seconds.
    /// @param _proxy Address of Proxy contract.
    function MultiSigWalletWithTimeLockExceptRemoveAuthorizedAddress(
        address[] _owners,
        uint _required,
        uint _secondsTimeLocked,
        address _proxy)
        public
        MultiSigWalletWithTimeLock(_owners, _required, _secondsTimeLocked)
    {
        PROXY_CONTRACT = _proxy;
    }

    /// @dev Allows execution of removeAuthorizedAddress without time lock.
    /// @param transactionId Transaction ID.
    function executeRemoveAuthorizedAddress(uint transactionId)
        public
        notExecuted(transactionId)
        //NOTE: confirmationTimeSet() modifier is being used for checking M out of N confirmations
        //      Seems tricky!
        confirmationTimeSet(transactionId)
        validRemoveAuthorizedAddressTx(transactionId)
    {
        Transaction tx = transactions[transactionId];
        tx.executed = true;
        if (tx.destination.call.value(tx.value)(tx.data)) // FLAG: EXTERNAL
            Execution(transactionId);
        else {
            ExecutionFailure(transactionId);
            tx.executed = false;
        }
    }

    function bytes4FromBytes(bytes data)
        public
        constant
        returns (bytes4)
    {
        require(data.length >= 4);
        
        bytes4 first4Bytes;
        
        assembly {
            first4Bytes := mul(div(mload(add(data, 0x20)), 0x100000000000000000000000000000000000000000000000000000000), 0x100000000000000000000000000000000000000000000000000000000)
        }
        
        return first4Bytes;
    }

    /// @dev Compares first 4 bytes of byte array to removeAuthorizedAddress function signature.
    /// @param data Transaction data.
    /// @return Successful if data is a call to removeAuthorizedAddress.
    // function isFunctionRemoveAuthorizedAddress(bytes data)
    //     public
    //     constant
    //     returns (bool)
    // {
    //     //NOTE: This whole function wastes a lot of gas. [`bytes`tightly packed arrays cannot be cast to bytes4 as I originally thought!]
    //     //      But in assembly this would be SO MUCH lean. I have working assembly code to do  just this!
    //     bytes4 removeAuthorizedAddressSignature = bytes4(sha3("removeAuthorizedAddress(address)"));
    //     for (uint i = 0; i < 4; i++) {
    //         assert(data[i] == removeAuthorizedAddressSignature[i]);
    //     }
    //     return true;
    // }


}
