import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";

async function main(): Promise<void> {
  const Logic: ContractFactory = await ethers.getContractFactory("Treasury");
  const logic: Contract = await upgrades.deployProxy(Logic, ["0x25433bACDa338631a9e8a493c4b280d94497f4Ae", "0x5498BB86BC934c8D34FDA08E81D444153d0D06aD"], { kind: "uups", initializer: "init" });
  await logic.deployed();
  console.log("Logic Proxy Contract deployed to : ", logic.address);
  console.log("Logic Contract implementation address is : ", await upgrades.erc1967.getImplementationAddress(logic.address));
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
