const { ethers, upgrades } = require("hardhat");

async function main() {
  const SimpleERC20Swapper = await ethers.getContractFactory(
    "SimpleERC20Swapper"
  );

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  console.log("Deploying Contracts...");
  const simpleERC20Swapper = await upgrades.deployProxy(
    SimpleERC20Swapper,
    [deployer.address],
    {
      initializer: "initialize",
    }
  );

  // await simpleERC20Swapper.deployed();
  console.log("SimpleERC20Swapper deployed to:", simpleERC20Swapper.address);
  console.log("Done!");

  const factoryAddress = "0xc9f18c25Cfca2975d6eD18Fc63962EBd1083e978"; // Set the factory address
  const routerAddress = "0x86dcd3293C53Cf8EFd7303B57beb2a3F671dDE98"; // Set the router address
  await simpleERC20Swapper.setFactory(factoryAddress);
  await simpleERC20Swapper.setRouterContract(routerAddress);
}

main();
