import { Contract, ContractFactory } from "ethers";
import { ethers } from "hardhat";

async function main(): Promise<void> {
  const Factory: ContractFactory = await ethers.getContractFactory("CommandGate");
  const contract: Contract = await Factory.deploy("0x1c589c8697e9bae06f3bE6753ACd308DC5fE1600", "0x25433bACDa338631a9e8a493c4b280d94497f4Ae", "0xD39A527516d19b5cfddDd58A2544E52257a3323F");
  await contract.deployed();
  console.log("Contract deployed to : ", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });


  


