const DecentralisedLottery = artifacts.require("DecentralisedLottery");

module.exports = function (deployer) {
  deployer.deploy(DecentralisedLottery, 9096);
};