import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";
import * as dotenv from "dotenv";

dotenv.config();

async function main(): Promise<void> {
  const NFT: ContractFactory = await ethers.getContractFactory("Collectible721");

  const beaconImplement: Contract = await upgrades.upgradeBeacon(process.env.NFT_BEACON || "", NFT, {
    unsafeAllow: ["constructor", "delegatecall"],
  });

  await beaconImplement.deployed();
  console.log(`NFT beacon new implement upgraded at: ${beaconImplement.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
