pragma solidity ^0.4.11;

// FLAG: WE HAVE NO IDEA HOW THIS IS BEING DEPLOYED/CONFIGURED
// AdChain is a great example for readable deployment scripts
// FLAG: where is the actual reference to registry? It doesn't look like they're actually using it 
// despite the name of his file

import "./Exchange.sol";
import "./tokens/EtherToken.sol";
import "./base/Token.sol";
import "./base/Ownable.sol";
import "./base/SafeMath.sol";

contract TokenDistributionWithRegistry is Ownable, SafeMath {

    event Initialized(
        address maker,
        address taker,
        address makerToken,
        address takerToken,
        address feeRecipient,
        uint makerTokenAmount,
        uint takerTokenAmount,
        uint makerFee,
        uint takerFee,
        uint expirationTimestampInSec,
        uint salt,
        uint8 v,
        bytes32 r,
        bytes32 s
    );

    event Finished();

    address public PROXY_CONTRACT; 
    address public EXCHANGE_CONTRACT;
    address public PROTOCOL_TOKEN_CONTRACT;
    address public ETH_TOKEN_CONTRACT;

    Exchange exchange;
    Token protocolToken;
    EtherToken ethToken;

    mapping (address => bool) public registered;
    mapping (address => uint) public contributed;

    bool public isInitialized; // could I change these? 
    bool public isFinished;
    uint public ethCapPerAddress;
    Order order;

    // NOTE: in this case, the order has the additional v, r, s values. 
    // FLAG: in this case, the orderHash is not the same as the getOrderHash() function? Actually, it's not specified here, this is just a struct
    struct Order {
        address maker;
        address taker;
        address makerToken;
        address takerToken;
        address feeRecipient;
        uint makerTokenAmount;
        uint takerTokenAmount;
        uint makerFee;
        uint takerFee;
        uint expirationTimestampInSec;
        uint salt;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32 orderHash;
    } 

    modifier distributionInitialized() {
        assert(isInitialized);
        _;
    }

    modifier distributionNotInitialized() {
        assert(!isInitialized);
        _;
    }

    modifier distributionNotFinished() {
        assert(!isFinished);
        _;
    }

    modifier callerIsRegistered() {
        require(registered[msg.sender]);
        _;
    }

    function TokenDistributionWithRegistry(
        address _exchange,
        address _proxy,
        address _protocolToken,
        address _ethToken,
        uint _capPerAddress)
    {
        PROXY_CONTRACT = _proxy;
        EXCHANGE_CONTRACT = _exchange;
        PROTOCOL_TOKEN_CONTRACT = _protocolToken;
        ETH_TOKEN_CONTRACT = _ethToken;
        ethCapPerAddress = _capPerAddress;

        // NOTE: store a reference to an Exchange, Token, and EtherToken contract... why?
        exchange = Exchange(_exchange); 
        protocolToken = Token(_protocolToken);
        ethToken = EtherToken(_ethToken);
    }

    /// @dev Allows users to fill stored order by sending ETH to contract.
    // NOTE: interestingly, this is doing exactly what that intern had suggested. Cool idea. 
    // sybil risk?
    // Any benefit to paying more than one purchase order at once? 
    function()
        payable
    {
        fillOrderWithEth();
    }


    /// @dev Stores order and initializes distribution.
    // NOTE: what does this mean "initializes distribution?"
    // This name is terrible. 
    /// @param orderAddresses Array of order's maker, taker, makerToken, takerToken, and feeRecipient.
    /// @param orderValues Array of order's makerTokenAmount, takerTokenAmount, makerFee, takerFee, expirationTimestampInSec, and salt.
    /// @param v ECDSA signature parameter v.
    /// @param r CDSA signature parameters r.
    /// @param s CDSA signature parameters s.
    function init( 
        address[5] orderAddresses,
        uint[6] orderValues,
        uint8 v,
        bytes32 r,
        bytes32 s)
        distributionNotInitialized // NOTE: this ensures the fucntion can only be called once.
        // So the whole thing is essentially one big maker order =()
        onlyOwner
    {
        // FLAG: this pattern is repeated frequently... but it's basically using a native constructor already. 
        // what is this one doing with the v,r,s? 
        // FLAG: wait... so this sets the top level `order` variable
        order = Order({
            maker: orderAddresses[0], 
            taker: orderAddresses[1],
            makerToken: orderAddresses[2],
            takerToken: orderAddresses[3], 
            feeRecipient: orderAddresses[4], // FLAG: will there be a feeRecipient? Add a check to ensure no fees? 
            makerTokenAmount: orderValues[0],
            takerTokenAmount: orderValues[1],
            makerFee: orderValues[2],
            takerFee: orderValues[3], // if non-zero...
            expirationTimestampInSec: orderValues[4],
            salt: orderValues[5], // FLAG: 
            v: v, // FLAG: signature values. But not the ones associated with `orderHash`
            r: r,
            s: s,
            orderHash: getOrderHash(orderAddresses, orderValues)
            // NOTE: consider using 
            // exchange.getOrderHash(orderAddresses, orderValues);
            // what would be the gas cost though? I suppose that requires another read to get the bytecode? 
            // Interesting that DRY and gas efficiency are a trade off
            // Consider adding to the best practices. 
        });

        require(order.taker == address(this)); // this line ensures `this` contract is the taker
        require(order.makerToken == PROTOCOL_TOKEN_CONTRACT);
        require(order.takerToken == ETH_TOKEN_CONTRACT);

        // so this works by requiring that the _maker_ submits the v,r,s values from signing the orderHash
        // which they would do offline
        // NOTE: This ensures the the signature values are from the same private key as the order.maker
        //     who must submit the v,r,s which they obtain from signing sha3("\x19Ethereum Signed Message:\n32", order.orderHash)
        require(isValidSignature( // this translates to: 
            order.maker,          // return order.maker == ecrecover(
            order.orderHash,      //     sha3("\x19Ethereum Signed Message:\n32", order.orderHash), 
            v,                      // v,
            r,                      // r, 
            s                       // s 
        ));

        assert(setTokenAllowance(order.takerToken, order.takerTokenAmount));
        isInitialized = true;

        // NOTE: This is pretty big. Should we suggest indexing some of it? Or is that handled by default?
        // Whatever it only runs once. 
        Initialized(
            order.maker,
            order.taker,
            order.makerToken,
            order.takerToken,
            order.feeRecipient,
            order.makerTokenAmount,
            order.takerTokenAmount,
            order.makerFee,
            order.takerFee,
            order.expirationTimestampInSec,
            order.salt,
            order.v,
            order.r,
            order.s
        );
    }

    /// @dev Fills order using msg.value.
    function fillOrderWithEth()
        payable
        distributionInitialized
        distributionNotFinished
        callerIsRegistered
    {
        // why is this all needed? Wouldn't the Exchange just handle it? 
        uint remainingEth = safeSub(
                                order.takerTokenAmount, //ie. the total ETH requested
                                exchange.getUnavailableTakerTokenAmount(order.orderHash) // filled or cancelled
                            ); // FLAG: EXTERNAL
        uint allowedEth = safeSub(
                            ethCapPerAddress, 
                            contributed[msg.sender]
                        );
        uint ethToFill = min256(min256(msg.value, remainingEth), allowedEth);
        // wrap the ETH in ETH_TOKEN_CONTRACT
        ethToken.deposit.value(ethToFill)(); // FLAG: EXTERNAL
        // FLAG: the ethToken wrapper will start empty... but the original allowance will be for the full amount

        // FLAG: doing this before the exchange?  no that's probably safest
        contributed[msg.sender] = safeAdd(contributed[msg.sender], ethToFill);

        // NOTE: this @dev tag causes an error in solc
        // Fills an order with specified parameters and ECDSA signature, throws if specified amount not filled entirely.
        assert(exchange.fillOrKillOrder(
            [order.maker, 
            order.taker, // why can't this just be msg.sender?
            order.makerToken, order.takerToken, order.feeRecipient],
            [order.makerTokenAmount, order.takerTokenAmount, order.makerFee, order.takerFee, order.expirationTimestampInSec, order.salt],
            ethToFill, // FLAG: why fillOrKill? This includes redundant checks, since we've already determined that the amount is available
            order.v,
            order.r,
            order.s
        ));

        // that's a lot of mul/div: (totalZRX / totalETH) * ethPaid
        uint filledProtocolToken = safeDiv(safeMul(order.makerTokenAmount, ethToFill), order.takerTokenAmount);
        
        // Send the token to the contributor
        assert(protocolToken.transfer(msg.sender, filledProtocolToken));

        // return extra 
        if (ethToFill < msg.value) {
            assert(msg.sender.send(safeSub(msg.value, ethToFill)));
        }
        if (remainingEth == ethToFill) {// FLAG: why not do just one more goddamn check?
            isFinished = true;
            Finished();
        }
    }

    /// @dev Approves proxy to transfer a token.
    /// @param _token Address of the token to approve.
    /// @param _allowance Amount of token proxy can transfer.
    /// @return Success of approval.
    function setTokenAllowance(address _token, uint _allowance)
        onlyOwner
        returns (bool success)
    {
        // NOTE: this calls the ZRX token
        assert(Token(_token).approve(PROXY_CONTRACT, _allowance)); // FLAG: external
        return true;
    }

    /// @dev Sets the cap per address to a new value.
    // NOTE: this is for ALL addresses. 
    /// @param _newCapPerAddress New value of the cap per address.
    function setCapPerAddress(uint _newCapPerAddress)
        onlyOwner
    {
        ethCapPerAddress = _newCapPerAddress;
    }

    /// @dev Changes registration status of an address for participation.
    /// @param target Address that will be registered/deregistered.
    /// @param isRegistered New registration status of address.
    function changeRegistrationStatus(address target, bool isRegistered)
        onlyOwner
    {
        registered[target] = isRegistered;
    }

    /// @dev Changes registration statuses of addresses for participation.
    /// @param targets Addresses that will be registered/deregistered.
    /// @param isRegistered New registration status of addresss.
    function changeRegistrationStatuses(address[] targets, bool isRegistered)
        onlyOwner
    {
        for (uint i = 0; i < targets.length; i++) {
            changeRegistrationStatus(targets[i], isRegistered);
        }
    }

    /// @dev Calculates Keccak-256 hash of order with specified parameters.
    /// @param orderAddresses Array of order's maker, taker, makerToken, takerToken, and feeRecipient.
    /// @param orderValues Array of order's makerTokenAmount, takerTokenAmount, makerFee, takerFee, expirationTimestampInSec, and salt.
    /// @return Keccak-256 hash of order.
    // FLAG: tests are ensuring that js implementation always matches
    function getOrderHash(address[5] orderAddresses, uint[6] orderValues)
        constant
        returns (bytes32 orderHash)
    {
        // FLAG: why not call this on the Exchange contract itself? Prolly saves on gas. 
        // FLAG: maybe consider using a lib?
        return sha3(
            EXCHANGE_CONTRACT,
            orderAddresses[0],
            orderAddresses[1],
            orderAddresses[2],
            orderAddresses[3],
            orderAddresses[4],
            orderValues[0],
            orderValues[1],
            orderValues[2],
            orderValues[3],
            orderValues[4],
            orderValues[5]
        );
    }

    /// @dev Verifies that an order signature is valid.
    /// @param pubKey Public address of signer.
    /// @param hash Signed Keccak-256 hash.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    /// @return Validity of order signature.
    function isValidSignature(
        address pubKey,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s)
        constant
        returns (bool isValid)
    {
        return pubKey == ecrecover(
            // NOTE: why is everything prefixed with this? 
            sha3("\x19Ethereum Signed Message:\n32", hash), 
            v,
            r,
            s
        );
    }
}
