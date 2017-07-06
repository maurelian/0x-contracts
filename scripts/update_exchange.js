const fs = require('fs');
const _ = require('lodash');
const solc = require('solc');
const Web3 = require('web3');
const sha3 = require('crypto-js/sha3');

const proxyArtifact = require(`${__dirname}/../build/contracts/Proxy`);
const tokenRegistryArtifact = require(`${__dirname}/../build/contracts/TokenRegistry`);
const exchangeArtifact = require(`${__dirname}/../build/contracts/Exchange.json`);

const KOVAN_NETWORK_ID = 42;
const JSON_RPC_PORT = 8545;
const NODE_URL = `http://localhost:${JSON_RPC_PORT}`;

const getContractContents = path => {
  const contents = fs.readFileSync(`${__dirname}/../contracts/${path}`).toString();
  return {contents};
};

const exchangeContents = getContractContents('Exchange.sol').contents;
const inputs = {'Exchange.sol': exchangeContents};
const activateOptimiserFlag = 1;
const compiledExchange = solc.compile({sources: inputs}, activateOptimiserFlag, getContractContents);

let proxyKovanAddress;
let tokenRegistryKovanAddress;

try {
  proxyKovanAddress = proxyArtifact.networks[KOVAN_NETWORK_ID].address;
} catch (err) {
  throw new Error(`Proxy not deployed on network ${KOVAN_NETWORK_ID}`);
}

try {
  tokenRegistryKovanAddress = tokenRegistryArtifact.networks[KOVAN_NETWORK_ID].address;
} catch (err) {
  throw new Error(`TokenRegistry not deployed on network ${KOVAN_NETWORK_ID}`);
}

const exchangeContractReference = 'Exchange.sol:Exchange';
const exchangeABI = JSON.parse(compiledExchange.contracts[exchangeContractReference].interface);
const exchangeBytecode = `0x${compiledExchange.contracts[exchangeContractReference].bytecode}`;
const tokenRegistryABI = tokenRegistryArtifact.abi;

const web3 = new Web3(new Web3.providers.HttpProvider(NODE_URL));
const TokenRegistryContract = web3.eth.contract(tokenRegistryABI);
const tokenRegistryInstance = TokenRegistryContract.at(tokenRegistryKovanAddress);

web3.eth.getAccounts((err, accounts) => {
  const owner = accounts[0];
  tokenRegistryInstance.getTokenAddressBySymbol('ZRX', (err, zrxTokenAddress) => {
    if (err) {
      throw err;
    }
    const ExchangeContract = web3.eth.contract(exchangeABI);
    const gasEstimate = web3.eth.estimateGas({data: exchangeBytecode});
    const additionalGas = 500000;
    ExchangeContract.new(zrxTokenAddress, proxyKovanAddress, {
      data: exchangeBytecode,
      from: owner,
      gas: gasEstimate + additionalGas,
    }, (err, exchangeContractInstance) => {
      if (err && !exchangeContractInstance) {
        console.log(`Error encountered: ${err}`);
      } else if (!exchangeContractInstance.address) {
        console.log(`transactionHash: ${exchangeContractInstance.transactionHash}`);
      } else {
        console.log(`Exchange address: ${exchangeContractInstance.address}`);

        const newExchangeArtifact = _.assign({}, exchangeArtifact);
        newExchangeArtifact.abi = exchangeABI;
        newExchangeArtifact.unlinked_binary = exchangeBytecode;
        const kovanSpecificExchangeArtifact = newExchangeArtifact.networks[KOVAN_NETWORK_ID];
        kovanSpecificExchangeArtifact.address = exchangeContractInstance.address;
        kovanSpecificExchangeArtifact.updated_at = new Date().getTime();
        const kovanNetworkEvents = _.keys(kovanSpecificExchangeArtifact.events);
        _.each(kovanNetworkEvents, event => {
          delete kovanSpecificExchangeArtifact.events[event];
        });
        _.each(exchangeABI, item => {
          if (item.type === 'event') {
            const paramTypes = item.inputs.map(param => param.type).join(',');
            const signature = `${item.name}(${paramTypes})`;
            const outputLength = 256;
            kovanSpecificExchangeArtifact.events[`0x${sha3(signature, {outputLength})}`] = item;
          }
        });

        fs.writeFile(`${__dirname}/../build/contracts/Exchange.json`, JSON.stringify(newExchangeArtifact), (err) => {
          if (err) {
            throw err;
          }
          console.log('Exchange artifact updated!');
        });
      }
    });
  });
});
