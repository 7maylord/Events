import {ethers} from "hardhat";

async function verifyTicket() {
    const _event = await ethers.getContractAt("EventContract", "0x69A372b290322E336eFd85B5Fa52c6a16792DD1c");
    const owner = await ethers.provider.getSigner()
    const isVerified = await _event.validateTicket(1, owner.address);
    

    console.log("VERIFIED", isVerified)
} 


verifyTicket().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})