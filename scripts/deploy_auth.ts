import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";

async function main(): Promise<void> {
  const Logic: ContractFactory = await ethers.getContractFactory("Authority");
  const logic: Contract = await upgrades.deployProxy(Logic, [], { kind: "uups", initializer: "init" });
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
