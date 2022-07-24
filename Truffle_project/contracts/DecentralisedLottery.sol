// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/access/Ownable.sol";

contract DecentralisedLottery is Ownable{
    uint public jackpot = 0;

    struct playerStruct{
        address playerAddress;
        uint number;
        uint betSize;
        bool isPlaying;
    }

    playerStruct [][18] public playersArray;
    mapping(address => playerStruct) public playersMap;

    function play(uint guess) public payable {

        // Check if player has already played
        require(playersMap[msg.sender].isPlaying == false);

        // Number played can only be between 1 and 20 (1 < x < 19)
        require(1 < guess && guess < 19);

        // Bet amount is the 70% of the tx value. It contributes towards the jackpot
        uint bet = 70*msg.value/100;
        jackpot += bet;

        // Rest (30% of tx value) goes to the owner as a fee. Could be paid after finalization
        payable(owner()).transfer(msg.value-bet);

        // Store player and bet
        playersMap[msg.sender] = playerStruct(msg.sender, guess, bet, true);
        playersArray[guess-2].push(playerStruct(msg.sender, guess, bet, true)); // guess-2 because array indexing starts at 0 but playable numbers start at 2
    }

    function getPlayerAddressFromArray(uint index0, uint index1) public view returns(address){
        return playersArray[index0][index1].playerAddress;
    }

    function getPlayerNumberFromArray(uint index0, uint index1) public view returns(uint){
        return playersArray[index0][index1].number;
    }
}