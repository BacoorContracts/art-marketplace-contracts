import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";
import * as dotenv from "dotenv";

dotenv.config();

async function main(): Promise<void> {
  const Treasury: ContractFactory = await ethers.getContractFactory("Treasury");

  const beaconImplement: Contract = await upgrades.upgradeBeacon(process.env.TREASURY_BEACON || "", Treasury, {
    unsafeAllow: ["constructor", "delegatecall"],
  });

  await beaconImplement.deployed();
  console.log(`Treasury beacon new implement upgraded at: ${beaconImplement.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
