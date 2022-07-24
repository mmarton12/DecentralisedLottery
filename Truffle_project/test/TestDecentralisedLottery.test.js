const DecentralisedLottery = artifacts.require('DecentralisedLottery');
const assert = require('assert');


contract("DecentralisedLottery", (accounts) => {
    let decentralisedLottery;
    let expectedPlayerAddress;
    let expectedPlayersNumber;

    before(async () => {
        decentralisedLottery = await DecentralisedLottery.deployed();
    });

    describe("after playing the player info should be stored", async () => {
        before("playing using accounts[0] with address 0x777925B7e586F0De1C2312ac9bcd559CBac3eFB0", async () => {
            await decentralisedLottery.play(8, {from: accounts[0], value: 1e16});
            expectedPlayerAddress = accounts[0]
/*             const stuff = await decentralisedLottery.getPlayerAddressFromArray(6,0);
            console.log("resuktingplayeraddress: ", stuff);
            console.log("Logging: ", expectedPlayerAddress);
            console.log("playeraddresstostring: ", toString(expectedPlayerAddress)); */
            expectedPlayersNumber = '8';
        });

        it("can fetch the player's address", async () => {
            const resultingPlayerAddress = await decentralisedLottery.getPlayerAddressFromArray(6,0);
            console.log(resultingPlayerAddress);
            assert.equal(toString(resultingPlayerAddress), toString(expectedPlayerAddress), "The addresses should match");
        });

        it("can fetch the player's number", async () => {
            const playersNumber = await decentralisedLottery.getPlayerNumberFromArray(6,0);
            console.log(playersNumber);
            assert.equal(playersNumber, expectedPlayersNumber, "The numbers should match");
        })
    });
});