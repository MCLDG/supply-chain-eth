
const LotContract = artifacts.require("LotContract");

module.exports = function(deployer) {
  deployer.deploy(LotContract);
};
