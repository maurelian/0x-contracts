pragma solidity ^0.4.11;

import "./../base/StandardToken.sol";

contract ZRXToken is StandardToken {
    uint8 constant public decimals = 18;
    string constant public name = "0x Network Token";
    string constant public symbol = "ZRX";

    function ProtocolToken() { // FLAG: misnamed constructor?
        totalSupply = 10**26; // 100M tokens, 18 decimal places
        balances[msg.sender] = totalSupply;
    }

}
