const IRM = artifacts.require("IRMcontract");
const ASI = artifacts.require("ASIcontract");

module.exports = function(deployer) {
  deployer.deploy(IRM);
  //deployer.link(IRM, ASI);
  deployer.deploy(ASI,"0x9d13C6D3aFE1721BEef56B55D303B09E021E27ab",IRM.adress);
};
