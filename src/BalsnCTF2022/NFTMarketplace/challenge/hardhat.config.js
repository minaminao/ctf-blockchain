require("@nomicfoundation/hardhat-toolbox");

task("execute", "Execute")
  .addParam("nonce", "Nonce")
  .addParam("bytecode", "User contract")
  .setAction(async (taskArgs) => {
    // set timeout
    setTimeout(() => {
      throw new Error("Timeout");
    }, 30000);

    // create random owner
    const user = ethers.Wallet.createRandom().connect(ethers.provider);
    const owner = ethers.Wallet.createRandom().connect(ethers.provider);
    const accounts = await hre.ethers.getSigners();
    await accounts[0].sendTransaction({
      to: owner.address,
      value: ethers.utils.parseEther("10"),
    });
    await accounts[0].sendTransaction({
      to: user.address,
      value: ethers.utils.parseEther("10"),
    });

    // deploy user contract
    const contractAbi = ["function execute(address)"];
    const contractByteCode = taskArgs.bytecode;
    const userContractFactory = new ethers.ContractFactory(
      contractAbi,
      contractByteCode,
      user
    );
    const userContract = await userContractFactory.deploy({ gasLimit: 30000000 });
    // console.log("user contract:", userContract.address);

    // create NFTMarketplace contract
    const factory = await hre.ethers.getContractFactory("NFTMarketplace", {
      signer: owner,
    });
    const nftMarketplace = await factory.deploy();
    await nftMarketplace.deployed();
    // console.log("NFTMarketplace:", nftMarketplace.address);

    // execute user contract
    await userContract.execute(nftMarketplace.address, { gasLimit: 30000000 });

    // verify answer
    const arrayEvent = await nftMarketplace.queryFilter("GetFlag");
    if (arrayEvent[0].event === "GetFlag") {
      console.log("Get Flag:", taskArgs.nonce);
    }
  });

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
};
