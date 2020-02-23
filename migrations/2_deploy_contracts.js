
const PackageLabels = artifacts.require("PackageLabels");

module.exports = function(deployer) {
  deployer.deploy(PackageLabels);
};
