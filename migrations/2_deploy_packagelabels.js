
const PackageLabelsContract = artifacts.require("PackageLabelsContract");

module.exports = function(deployer) {
  deployer.deploy(PackageLabelsContract);
};
