const fs = require('fs');
const solc = require('solc');
const Web3 = require('web3');
const sha3 = require('crypto-js/sha3');

const KOVAN_NETWORK_ID = 42;

const findImports = path => {
  const contents = fs.readFileSync(`${__dirname}/../contracts/${path}`).toString();
  return {contents};
};

const exchangeContents = fs.readFileSync(`${__dirname}/../contracts/Exchange.sol`).toString();
const inputs = {'Exchange.sol': exchangeContents};
const compiled = solc.compile({sources: inputs}, 1, findImports);

const proxyArtifact = require(`${__dirname}/../build/contracts/Proxy.json`);
const tokenRegistryArtifact = require(`${__dirname}/../build/contracts/TokenRegistry.json`);
const proxyKovanAddress = proxyArtifact.networks[KOVAN_NETWORK_ID].address;
const tokenRegistryKovanAddress = tokenRegistryArtifact.networks[KOVAN_NETWORK_ID].address;

const exchangeABI = JSON.parse(compiled.contracts['Exchange.sol:Exchange'].interface);
const exchangeBytecode = `0x${compiled.contracts['Exchange.sol:Exchange'].bytecode}`;
const tokenRegistryABI = tokenRegistryArtifact.abi;

const web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));
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
    ExchangeContract.new(zrxTokenAddress, proxyKovanAddress, {
      data: exchangeBytecode,
      from: owner,
      gas: gasEstimate + 500000,
    }, (err, exchangeContractInstance) => {
      if (err) {
        console.log(err);
      } else if (!exchangeContractInstance.address) {
        console.log(`transactionHash: ${exchangeContractInstance.transactionHash}`);
      } else {
        console.log(`address: ${exchangeContractInstance.address}`);
        const exchangeArtifact = require(`${__dirname}/../build/contracts/Exchange.json`);
        const newExchangeArtifact = Object.assign({}, exchangeArtifact);
        newExchangeArtifact.abi = exchangeABI;
        newExchangeArtifact.unlinked_binary = exchangeBytecode;
        const network = newExchangeArtifact.networks[KOVAN_NETWORK_ID];
        network.address = exchangeContractInstance.address;
        network.updated_at = new Date().getTime();
        const networkEvents = Object.keys(network.events);
        networkEvents.forEach(event => {
          delete network.events[event];
        });
        exchangeABI.forEach(item => {
          if (item.type === 'event') {
            const signature = `${item.name}(${item.inputs.map(param => param.type).join(',')})`;
            network.events[`0x${sha3(signature, {outputLength: 256})}`] = item;
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
