
const TradeItemContract = artifacts.require("TradeItemContract");

module.exports = function(deployer) {
  deployer.deploy(TradeItemContract);
};
