import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";

const proxyAddress: string = "0x0C336BD43791571E91a419569B20e8Ef18E30986";

async function main(): Promise<void> {
  console.log("Deploying LogicV2 contract...");
  const Logic: ContractFactory = await ethers.getContractFactory("Marketplace");
  const logic: Contract = await upgrades.upgradeProxy(proxyAddress, Logic);
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
