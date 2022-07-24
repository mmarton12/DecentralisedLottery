const DecentralisedLottery = artifacts.require('DecentralisedLottery');
const assert = require('assert');
const toBN = web3.utils.toBN;


contract("DecentralisedLottery", (accounts) => {
    let decentralisedLottery;

    before(async () => {
        decentralisedLottery = await DecentralisedLottery.deployed();
    });

    describe("after playing the player info should be stored and the fee should be transfered", async () => {
        let expectedPlayerAddress;
        let expectedPlayersNumber;
        let playResult;
        let playValue;

        before("playing using accounts[0] with address 0x777925B7e586F0De1C2312ac9bcd559CBac3eFB0", async () => {
            playValue = 1e16;
            playResult = await decentralisedLottery.play(8, {from: accounts[0], value: playValue});
            expectedPlayerAddress = accounts[0]
            expectedPlayersNumber = '8';
        });

        it("can fetch the player's address", async () => {
            const resultingPlayerAddress = await decentralisedLottery.getPlayerAddressFromArray(6,0);
            assert.equal(toString(resultingPlayerAddress), toString(expectedPlayerAddress), "The addresses should match");
        });

        it("can fetch the player's number", async () => {
            const playersNumber = await decentralisedLottery.getPlayerNumberFromArray(6,0);
            assert.equal(playersNumber, expectedPlayersNumber, "The numbers should match");
        });

        it("transfers 30% of the bet to the owner", async () => {
            assert.equal(playResult.logs[0].args._value.toString(), (playValue*0.3).toString(), "The transferred amount should be the 30% of the bet")
            assert.equal(playResult.logs[0].args._from, expectedPlayerAddress, "The sender should be the player");
            assert.equal(playResult.logs[0].args._to, accounts[0], "The recipient should be the owner");
        });
    });

    describe.only("after finalization the winners should be paid proportionally to their bets", async () => {
        before("playing with players and then finalize with owner", async () => {
            await decentralisedLottery.play(8, {from: accounts[5], value: web3.utils.toWei('1', 'ether')});
            await decentralisedLottery.play(9, {from: accounts[6], value: web3.utils.toWei('1', 'ether')});
            await decentralisedLottery.play(9, {from: accounts[7], value: web3.utils.toWei('1', 'ether')});

            finalizeResult = await decentralisedLottery.finalize({from: accounts[0]});
        });

        it("should pay accounts 6 and 7 1.05 eth ((1+1+1)*70%/2)", async () => {
            assert.equal(finalizeResult.logs[0].args._from, decentralisedLottery.address, "The contract should pay the winners");
            assert.equal(finalizeResult.logs[0].args._to, accounts[6], "Account 6 should be paid")
            assert.equal(finalizeResult.logs[0].args._value.toString(), web3.utils.toWei('1.05', 'ether'), "Account 6 should be paid 1.05 eth");

            assert.equal(finalizeResult.logs[1].args._from, decentralisedLottery.address, "The contract should pay the winners");
            assert.equal(finalizeResult.logs[1].args._to, accounts[7], "Account 7 should be paid")
            assert.equal(finalizeResult.logs[1].args._value.toString(), web3.utils.toWei('1.05', 'ether'), "Account 7 should be paid 1.05 eth");

        })
    })
});