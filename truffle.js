module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*', // Match any network id
    },
    kovan: {
      host: 'localhost',
      port: 8546,
      network_id: '42',
      gas: 4612388,
    }, 
    coverage: {
      host: "localhost",
      network_id: "*",
      port: 8555,         // <-- Use port 8555  
      gas: 0xfffffffffffffff, // <-- Use this high gas value
      gasPrice: 0x01      // <-- Use this low gas price
    }
  },
  test_directory: 'transpiled/test',
  migrations_directory: 'transpiled/migrations',
};
