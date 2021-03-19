const CipaCoin = artifacts.require("CipaCoins");

module.exports = function(deployer) {
  deployer.deploy(CipaCoin);
};
