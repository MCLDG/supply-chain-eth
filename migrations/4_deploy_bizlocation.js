
const BizLocationContract = artifacts.require("BizLocationContract");

module.exports = function(deployer) {
  deployer.deploy(BizLocationContract);
};
