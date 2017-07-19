import { ContractInstance } from '../util/types';
import { Artifacts } from '../util/artifacts';
const {
  Proxy,
  Exchange,
  TokenRegistry,
} = new Artifacts(artifacts);

let proxy: ContractInstance;
module.exports = (deployer: any) => {
  deployer.then(() => {
    return Promise.all([
      Proxy.deployed(),
      TokenRegistry.deployed(),
    ]);
  })
  .then((instances: ContractInstance[]) => {
    let tokenRegistry: ContractInstance;
    [proxy, tokenRegistry] = instances;
    return tokenRegistry.getTokenAddressBySymbol('ZRX');
  })
  // NOTE: here is where the ZRX token's symbol is set, and the Exchange is deployed
  .then((ptAddress: string) => {
     // NOTE: ptAddress = "protocol token"
    return deployer.deploy(Exchange, ptAddress, proxy.address);
  }).then(() => {
    return proxy.addAuthorizedAddress(Exchange.address);
  });
};
