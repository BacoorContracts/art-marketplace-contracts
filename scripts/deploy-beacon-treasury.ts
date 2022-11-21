import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";
import * as dotenv from "dotenv";
import { ContractAddressOrInstance } from "@openzeppelin/hardhat-upgrades/dist/utils/contract-types";

dotenv.config();

async function main(): Promise<void> {
  const Treasury: ContractFactory = await ethers.getContractFactory("Treasury");

  const existed: boolean = false;
  let implementAddress: ContractAddressOrInstance;
  if (existed) implementAddress = process.env.TREASURY_BEACON as ContractAddressOrInstance;
  else {
    const beaconImplement: Contract = await upgrades.deployBeacon(Treasury, {
      unsafeAllow: ["constructor", "delegatecall"],
    });

    await beaconImplement.deployed();
    console.log(`Treasury beacon implement deployed at: ${beaconImplement.address}`);
    implementAddress = beaconImplement.address;
  }

  let nativeToUSDPriceFeed: ContractAddressOrInstance;
  nativeToUSDPriceFeed = process.env.AVAX_PRICE_FEED as ContractAddressOrInstance;
  const beaconProxy: Contract = await upgrades.deployBeaconProxy(
    implementAddress,
    Treasury,
    [process.env.AUTHORITY, nativeToUSDPriceFeed],
    {
      kind: "uups",
      initializer: "init",
    },
  );
  await beaconProxy.deployed();
  console.log(`Proxy deployed at ${beaconProxy.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
