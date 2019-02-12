const Token = artifacts.require("./Token.sol");
const Exchange = artifacts.require("./Exchange.sol");
const Web3 = require("web3");
const BN = require("bn.js");
const conversionRate = new BN(2).mul(new BN(10).pow(new BN(16)))

module.exports = function(deployer, network, accounts) {

    let owner = accounts[0];
    let tokenA; 
    let tokenB;

    return deployer.deploy(Token, "ACME Corporation", "ACME", 18, {from: owner})
    .then(() => {
        return Token.deployed();
    }).then(_tokenA => {
        tokenA = _tokenA;
        return deployer.deploy(Token, "Umbrella Corporation", "UMB", 18, {from: owner});
    }).then(()=> {
        return Token.deployed();
    }).then(_tokenB => {
        tokenB = _tokenB;
        return deployer.deploy(Exchange, conversionRate, tokenB.address, tokenA.address, {from: owner});
    }).then(()=> {
        return tokenA.addMinter(Exchange.address, {from: owner});
    }).then(() => {
        return tokenB.addMinter(Exchange.address, {from: owner});
    }).then(() => {
        console.log(`
                Smart contract addresses
            ---------------------------------
            ACMEToken :     ${tokenA.address}
            UmbrellaToken:  ${tokenB.address}
            Exchange:       ${Exchange.address}
        `);
    })
}