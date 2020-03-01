
const MicrobatchToken = artifacts.require("MicrobatchToken");

module.exports = function(deployer) {
  deployer.deploy(MicrobatchToken);
};
