import * as chai from 'chai';
import * as dirtyChai from 'dirty-chai';
import ChaiBigNumber = require('chai-bignumber');

export const chaiSetup = {
    configure() {
        chai.config.includeStack = true;
        chai.use(ChaiBigNumber());
        chai.use(dirtyChai);
    },
};
