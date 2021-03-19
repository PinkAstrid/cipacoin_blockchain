const CipaCoin = artifacts.require("CipaCoin");

module.exports = function(deployer) {
  deployer.deploy(CipaCoin);
};
