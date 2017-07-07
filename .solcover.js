module.exports = {
    testrpcOptions: '--networkId 50',
    testCommand: `${process.env.PWD}/node_modules/truffle/cli.js test --network coverage`,
    norpc: true,
};