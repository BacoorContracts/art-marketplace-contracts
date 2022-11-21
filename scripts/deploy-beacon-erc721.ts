import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";
import * as dotenv from "dotenv";
import { ContractAddressOrInstance } from "@openzeppelin/hardhat-upgrades/dist/utils/contract-types";

dotenv.config();

async function main(): Promise<void> {
  const NFT: ContractFactory = await ethers.getContractFactory("Collectible721");

  const existed: boolean = false;
  let implementAddress: ContractAddressOrInstance;
  if (existed) implementAddress = process.env.NFT_BEACON as ContractAddressOrInstance;
  else {
    const beaconImplement: Contract = await upgrades.deployBeacon(NFT, {
      unsafeAllow: ["constructor", "delegatecall"],
    });

    await beaconImplement.deployed();
    console.log(`NFT beacon implement deployed at: ${beaconImplement.address}`);
    implementAddress = beaconImplement.address;
  }

  let [name, symbol, baseURI, baseExtension, mintPrice, chaindIdentifier] = [
    "",
    "",
    "",
    "",
    ethers.utils.parseEther("10"),
    0,
  ];
  const beaconProxy: Contract = await upgrades.deployBeaconProxy(
    implementAddress,
    NFT,
    [process.env.AUTHORITY, process.env.TREASURY, name, symbol, baseURI, baseExtension, mintPrice, chaindIdentifier],
    { kind: "uups", initializer: "init" },
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
