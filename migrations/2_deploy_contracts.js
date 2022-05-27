const AXSToken = artifacts.require("AXSToken");
const SLPToken = artifacts.require("SLPToken");
const AxieNFT = artifacts.require("AxieNFT");
const Marketplace = artifacts.require("Marketplace")


module.exports = function(deployer) {
  deployer.deploy(AXSToken);
  deployer.deploy(SLPToken);
  deployer.deploy(AxieNFT);
  deployer.deploy(Marketplace, 425)
};
