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
        bool hasBeenPaid;
    }

    // Struct storing players (index is used to store number)
    playerStruct [][18] private playersArray;
    // Map for storing addresses and lottery entries
    mapping(address => playerStruct) private playersMap;
    // Sum of bets for the numbers
    uint [18] betsForNumbers;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

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
        emit Transfer(msg.sender, owner(), msg.value-bet);

        // Store player and bet
        playersMap[msg.sender] = playerStruct(msg.sender, guess, bet, true, false);
        // guess-2 because array indexing starts at 0 but playable numbers start at 2
        playersArray[guess-2].push(playerStruct(msg.sender, guess, bet, true, false)); 
        betsForNumbers[guess-2] += bet;
    }

    function getPlayerAddressFromArray(uint index0, uint index1) public view returns(address){
        return playersArray[index0][index1].playerAddress;
    }

    function getPlayerNumberFromArray(uint index0, uint index1) public view returns(uint){
        return playersArray[index0][index1].number;
    }

    function finalize() public onlyOwner{
        //TODO: generate random number
        uint winningNumber = 7;
        uint i;

        // Paying the winners
        for(i = 0; i<playersArray[winningNumber].length; i++){
            address payable winnerAddr = payable(playersArray[winningNumber][i].playerAddress);
            uint playerBet = playersArray[winningNumber][i].betSize;
            uint amountWon = playerBet * jackpot / betsForNumbers[winningNumber];       // Jackpot gets distributed proportionally to the bets
            
            if(playersMap[winnerAddr].hasBeenPaid == false){
                playersMap[winnerAddr].hasBeenPaid = true;
                winnerAddr.transfer(amountWon);
                emit Transfer(address(this), winnerAddr, amountWon);
            }
        }

        // No winners (returns)
        if(i == 0){
            for(i = 0; i < 18; i++){
                for(uint j = 0; j < playersArray[i].length; j++){
                    address payable addr = payable(playersArray[i][j].playerAddress);
                    uint playerBet = playersArray[i][j].betSize;

                    if(playersMap[addr].hasBeenPaid == false){
                        playersMap[addr].hasBeenPaid = true;
                        addr.transfer(playerBet);
                        emit Transfer(address(this), addr, playerBet);
                    }
                }
            }
        }
        restartLottery();
    }
        // Deletig data from the previous round
        function restartLottery() private{
        delete betsForNumbers;
        jackpot = 0;
        for(uint i = 0; i < 18; i++){
            for(uint j = 0; j < playersArray[i].length; j++){
                address addr = playersArray[i][j].playerAddress;
                delete playersMap[addr];
            }
        }
        delete playersArray;
    }
}