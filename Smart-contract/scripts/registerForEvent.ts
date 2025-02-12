import {ethers} from "hardhat";

async function registerEvent() {
    const event = await ethers.getContractAt("EventContract", "0x69A372b290322E336eFd85B5Fa52c6a16792DD1c");
    const owner = await ethers.provider.getSigner()
    const block = await ethers.provider.getBlock("latest");
    const latestTime = block?.timestamp || Math.floor(Date.now() / 1000);
    
    const createTicket = await event.createEventTicket( 1, "MayNFT", "MNT")
    await createTicket.wait();
    console.log("Creating event ticket ...", createTicket.hash);
    
    const register = await event.registerForEvent(1, {value:ethers.parseUnits("0.00000001", 18)})
    await register.wait();
    console.log("Registering for event...", register.hash);
    
    const _hasRegistered = await event.hasRegistered(owner.address, 1);
    console.log("Has Registered", _hasRegistered)

} 


registerEvent().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})