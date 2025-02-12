import { ethers } from "hardhat";

async function createEvent() {
  // Connect to the deployed contract
  const eventContract = await ethers.getContractAt(
    "EventContract",
    "0x69A372b290322E336eFd85B5Fa52c6a16792DD1c"
  );

  // Get the latest block timestamp
  const block = await ethers.provider.getBlock("latest");
  const latestTime = block?.timestamp || Math.floor(Date.now() / 1000); 

  // Define event details
  const title = "Pool Party";
  const description = "For Matured Minds";
  const startDate = latestTime + 30;
  const endDate = latestTime + 86400;
  const eventType = 1; // Paid event
  const ticketPrice = ethers.parseUnits("0.00000001", 18); // 0.00000001 ETH
  const expectedGuestCount = 100;

  // Call createEvent function
  const event = await eventContract.createEvent(
    title,
    description,
    startDate,
    endDate,
    eventType,
    ticketPrice,
    expectedGuestCount
  );
  await event.wait();

  console.log("Event created successfully at:", event.hash);
}

createEvent().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
