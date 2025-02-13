import { ethers } from "hardhat";

async function main() {
  console.log("Deploying contract...");
  const event = await ethers.deployContract("EventContract");
  await event.waitForDeployment();

  const contractAddress = event.target as string;
  console.log(`EventContract successfully deployed to: ${contractAddress}`);

  await createEvent(contractAddress);
  await registerEvent(contractAddress);
  await verifyTicket(contractAddress);
}

async function createEvent(contractAddress: string) {
  console.log("Creating event...");
  const eventContract = await ethers.getContractAt("EventContract", contractAddress);

  const block = await ethers.provider.getBlock("latest");
  const latestTime = block?.timestamp || Math.floor(Date.now() / 1000);

  const title = "Pool Party";
  const description = "For Matured Minds";
  const startDate = latestTime + 30;
  const endDate = latestTime + 86400;
  const eventType = 1; // Paid event
  const ticketPrice = ethers.parseUnits("0.00000001", 18);
  const expectedGuestCount = 100;

  const eventTx = await eventContract.createEvent(
    title,
    description,
    startDate,
    endDate,
    eventType,
    ticketPrice,
    expectedGuestCount
  );
  await eventTx.wait();

  console.log("Event created successfully at:", eventTx.hash);
}

async function registerEvent(contractAddress: string) {
  console.log("Registering for event...");
  const event = await ethers.getContractAt("EventContract", contractAddress);
  const owner = await ethers.provider.getSigner();

  const createTicketTx = await event.createEventTicket(1, "MayNFT", "MNT");
  await createTicketTx.wait();
  console.log("Event ticket created...", createTicketTx.hash);

  const registerTx = await event.registerForEvent(1, {
    value: ethers.parseUnits("0.00000001", 18),
  });
  await registerTx.wait();
  console.log("User registered for event...", registerTx.hash);

  const hasRegistered = await event.hasRegistered(await owner.getAddress(), 1);
  console.log("User registration status:", hasRegistered);
}

async function verifyTicket(contractAddress: string) {
  console.log("Verifying ticket...");
  const event = await ethers.getContractAt("EventContract", contractAddress);
  const owner = await ethers.provider.getSigner();

  const isVerified = await event.validateTicket(1, await owner.getAddress());
  console.log("Ticket verification status at:", isVerified.hash);
}

// Execute deployment and function calls
main().catch((error) => {
  console.error("Error in script execution:", error);
  process.exitCode = 1;
});
