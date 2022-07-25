// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract DecentralisedLottery is Ownable, VRFConsumerBaseV2 {

    /************************************************************************************* */
    
  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 100000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  1;

  uint256 s_randomWords;
  uint256 s_requestId;
  address s_owner;

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() private {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords[0] % 18;
    payWinners(s_randomWords);
  }

    /************************************************************************************* */

    uint public jackpot = 0;

    uint winningNumber;

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

    /*function getPlayerAddressFromArray(uint index0, uint index1) public view returns(address){
        return playersArray[index0][index1].playerAddress;
    }

    function getPlayerNumberFromArray(uint index0, uint index1) public view returns(uint){
        return playersArray[index0][index1].number;
    }*/

    function payWinners(uint randNum) private {
        winningNumber = randNum;
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

    function finalize() public onlyOwner{
        requestRandomWords();
    }
    
    // Deletig data from the previous round
    function restartLottery() private{
        delete betsForNumbers;
        jackpot = 0;
        //winningNumber = 0;
        for(uint i = 0; i < 18; i++){
            for(uint j = 0; j < playersArray[i].length; j++){
                address addr = playersArray[i][j].playerAddress;
                delete playersMap[addr];
            }
        }
        delete playersArray;
    }
}