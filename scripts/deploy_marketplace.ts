import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";

async function main(): Promise<void> {
  const Logic: ContractFactory = await ethers.getContractFactory("Marketplace");
  const logic: Contract = await upgrades.deployProxy(Logic, ["0x25433bACDa338631a9e8a493c4b280d94497f4Ae", "0xD39A527516d19b5cfddDd58A2544E52257a3323F", ["0xfFE8597A65A56cdDF2B128547229176bED1a4540"], [1000], ["0xf2B0782C6C6bB5C375469E8151612E3b7b6cEa45"], [10000]], { kind: "uups", initializer: "init" });  await logic.deployed();
  console.log("Logic Proxy Contract deployed to : ", logic.address);
  console.log("Logic Contract implementation address is : ", await upgrades.erc1967.getImplementationAddress(logic.address));
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });

