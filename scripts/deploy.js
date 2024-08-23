const hre = require("hardhat");
const fs = require("fs");

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), 'ether');
};

async function main() {
  // Get the contract factory
  const TokenMaster = await hre.ethers.getContractFactory("TokenMaster");

  // Deploy the contract with the desired name and symbol
  const tokenMaster = await TokenMaster.deploy("TokenMaster", "TM");

  // Wait for the deployment to complete
  await tokenMaster.deployed();

  // Log the address of the deployed contract
  console.log("TokenMaster deployed to:", tokenMaster.address);

  // Save the deployed contract address to a file
  const data = {
    address: tokenMaster.address
  };

  fs.writeFileSync("deployedAddress.json", JSON.stringify(data, null, 2));
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
