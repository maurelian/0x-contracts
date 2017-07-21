pragma solidity ^0.4.11;

// NOTE: this is zeppelin

contract SafeMath {
    function safeMul(uint a, uint b) internal constant returns (uint) {
        uint c = a * b; // get the output first
        assert(a == 0 || c / a == b); // make sure it worked. 
        return c;
    }

    function safeDiv(uint a, uint b) internal constant returns (uint) {
        uint c = a / b; // FLAG: what is "safe" about this? 
        return c;
    }

    function safeSub(uint a, uint b) internal constant returns (uint) {
        assert(b <= a); // FLAG: should be return as these are user inputs
        return a - b;
    }

    function safeAdd(uint a, uint b) internal constant returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }


    // FLAG: unused/untested
    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}
