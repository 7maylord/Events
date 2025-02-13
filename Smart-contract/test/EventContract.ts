import {
    time,
    loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import hre from "hardhat";

describe('Event test', () => {
    
    const deployEventContract = async  () => {

        const ADDRESS_ZERO = '0x0000000000000000000000000000000000000000';

        const [owner, account1, account2, account3] = await hre.ethers.getSigners();

        const event = await hre.ethers.getContractFactory("EventContract");

        const deployEvent = await event.deploy();

        return { deployEvent, owner, account1, account2, account3, ADDRESS_ZERO };
    };

    describe("Deployment", () => {
        it('should be deployed by owner', async() => {
            let { deployEvent, owner } = await loadFixture(deployEventContract);

            const runner = deployEvent.runner as HardhatEthersSigner;

            expect(runner.address).to.equal(owner.address);
        });

        it('should not be address zero', async() => {
            let { deployEvent, ADDRESS_ZERO } = await loadFixture(deployEventContract);

            expect(deployEvent.target).to.not.be.equal(ADDRESS_ZERO);
        }); 
    });

    describe("Creating an Event", () => {
        it("Should allow the owner to create an event", async function () {
            const { deployEvent, owner } = await loadFixture(deployEventContract);
            const latestTime = await time.latest();

            await expect(
                deployEvent.createEvent(
                    "pool party",
                    "Matured minds only",
                    latestTime + 90,
                    latestTime + 86400, 
                    1,                    
                    hre.ethers.parseEther("0.1"),
                    100
                )
            ).to.emit(deployEvent, "EventCreated");

            const event = await deployEvent.events(1); 
            expect(event._title).to.equal("pool party");
            expect(event._ticketPrice).to.equal(hre.ethers.parseEther("0.1"));
            expect(event._expectedGuestCount).to.equal(100);
        });

        it("should not create event if end time is less than start time", async () => {
            const { deployEvent, owner } = await loadFixture(deployEventContract);
            const latestTime = await time.latest();
            await expect(deployEvent.createEvent("pool party", "Matured minds only", latestTime + 30, latestTime + 10, 1, 1, 20)).to.be.revertedWith('END DATE MUST BE GREATER');
          });

          it("should not create event if event is paid and fee is equal to 0", async () => {
            const { deployEvent, owner } = await loadFixture(deployEventContract);
            const latestTime = await time.latest();
            await expect(deployEvent.createEvent("pool party", "Matured minds only", latestTime + 30, latestTime + 86400, 1, 0, 10)).to.be.revertedWith("PAID EVENTS MUST HAVE TICKET PRICE > 0");
          });

    });

    describe("Registering for an Event", () => {
        // it("Should allow a user to register for a free event", async function () {
        //     const { deployEvent, account1 } = await loadFixture(deployEventContract);
        //     const latestTime = await time.latest();

        //     await deployEvent.createEvent(
        //         "Web3Bridge",
        //         "Free event",
        //         latestTime + 100,
        //         latestTime + 86400,
        //         0,
        //         0,
        //         10
        //     );

        //     await deployEvent.connect(account1).registerForEvent(1);
            
        //     expect(await deployEvent.hasRegistered(account1.address, 1)).to.equal(true);
        // });

        it("should not register for event if event has ended", async () => {
            const { deployEvent, account1 } = await loadFixture(deployEventContract);
            const latestTime = await time.latest();
            await deployEvent.createEvent("Web3Bridge", "Free event", latestTime + 30, latestTime + 150, 0, 20, 0);
            await time.increase(200);
            await expect(deployEvent.connect(account1).registerForEvent(1)).to.be.revertedWith('EVENT HAS ENDED');
        });

        
        it("Should not allow registration if the event is full", async function () {
            const { deployEvent, account1, account2, account3 } = await loadFixture(deployEventContract);
            const latestTime = await time.latest();
        
            await deployEvent.createEvent("Wedding Vows", "Exclusive event", latestTime + 100, latestTime + 86400, 0, 2, 0);
        
            await deployEvent.connect(account1).registerForEvent(1);
            await deployEvent.connect(account2).registerForEvent(1);
            const event = await deployEvent.events(1);
            console.log("...", event[0])
        
            await expect(deployEvent.connect(account3).registerForEvent(1)).to.be.revertedWith('REGISTRATION CLOSED');
            });
        });
        describe("Verify Attendance", () => {
            it("should verify attendance", async () => {
                const { deployEvent, owner, account1 } = await loadFixture(deployEventContract);
                const latestTime = await time.latest();
                await deployEvent.createEvent("pool party", "Matured minds only", latestTime + 30, latestTime + 86400, 1, 1, 20);
                await deployEvent.connect(account1).registerForEvent(1, {value: 1});
                expect(await deployEvent.validateTicket(1, account1.address)).to.emit(deployEvent, "AttendanceVerified")
            });
    
            it("should not verify attendance if event does not exist", async () => {
                const { deployEvent, account1 } = await loadFixture(deployEventContract);
                await expect(deployEvent.validateTicket(1, account1.address)).to.be.revertedWith('No Event');
            });
    
            it('should allot only organizer to verify attendance', async () => {
                const { deployEvent, account1, account2 } = await loadFixture(deployEventContract);
                const latestTime = await time.latest();
                await deployEvent.createEvent("pool party", "Matured minds only", latestTime + 30, latestTime + 86400, 1, 1, 20);
                await deployEvent.connect(account1).registerForEvent(1, {value: 1});
                await expect(deployEvent.connect(account2).validateTicket(1, account1.address)).to.be.revertedWith('ONLY ORGANIZER CAN VERIFY');
            });
    
        });
});
