// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

contract Lottery {

    uint256 saleEndTime;
    uint256 winningNum;
    uint256 balance_;
    address winnerAddress;
    uint256 leftBalance;

    address[] public winners;
    address[] public players;
    
    mapping(address => uint32) public tickets;
    mapping(address => bool) public hasTicket;
    mapping(address => uint8) playerCount;

    constructor() {
        saleEndTime = block.timestamp + 24 hours; // 배포 후 24시간 동안 티켓 판매
    }

    modifier checkTimeBuy() {
        require(block.timestamp < saleEndTime, "only buy after the sale phase");
        _;
    }

    modifier checkTimeDraw() {
        require(block.timestamp >= saleEndTime, "only draw after the sale phase");
        _;
    }

    function buy(uint32 _ticket) public payable checkTimeBuy {

        require(msg.value >= 0.1 ether && msg.value < (0.1 ether + 1), "Insufficient Funds");
        require(hasTicket[msg.sender] == false, "Not allowed duplication");// 중복 참여 금지

        players.push(msg.sender);
        tickets[msg.sender] = _ticket;
        hasTicket[msg.sender] = true;

    }


    function draw() public checkTimeDraw {
    require(playerCount[msg.sender] == 0, "No Draw During claim");
    winningNum = winningNumber();

    for (uint16 i = 0; i < players.length; i++) {
        if (tickets[players[i]] == winningNum) {
            bool alreadyWinner = false;

            // 중복 체크: winners 배열을 순회하면서 이미 추가된 주소인지 확인
            for (uint16 j = 0; j < winners.length; j++) {
                if (winners[j] == players[i]) {
                    alreadyWinner = true;
                    break; // 이미 추가된 경우 중단
                }
            }

            // 중복되지 않은 경우에만 winners 배열에 추가
            if (!alreadyWinner) {
                console.log("Winner found: ", players[i]);
                winners.push(players[i]);
            }
        }
    }
}

    

    function claim() public payable checkTimeDraw {
        if (winningNum == tickets[msg.sender]) {
            balance_ = address(this).balance; 
            uint256 payout = balance_ / winners.length;
            payable(msg.sender).call{value: payout}("");
            playerCount[msg.sender] = 1;
            if (winners.length > 0) {
                winners.pop();
            }
        
        } else {
            playerCount[msg.sender] = 0;
            saleEndTime = block.timestamp + 24 hours;
            hasTicket[msg.sender] = false;
        }
    }
        

    function winningNumber() public view returns (uint16) {
        require(players.length > 0, "No players participated");
        return uint16(uint256(keccak256(abi.encodePacked(block.timestamp, players.length))) % players.length);
    }
}