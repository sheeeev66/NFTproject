const NewContracts = artifacts.require("NewContracts");

module.exports = function (deployer) {
  deployer.deploy(NewContracts);
};
