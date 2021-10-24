//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";
import "./Best.sol";

contract Royalty {
    using Counters for Counters.Counter;

    Counters.Counter private counter;
    address payable private bank;
    Best private best;
    uint256 private bankPercent;
    uint256 private minEthToStartCycle;
    bool private lockClaim;
    uint256 private CYCLE_DURATION = 30 days;

    struct Cycle {
        uint256 startTimestamp;
        uint256 perTokenReward;
        uint256 balance;
        mapping(uint256 => bool) isClaimed;
    }

    mapping(uint256 => Cycle) private cycles;

    constructor(Best _best, uint256 _minEthToStartCycle, address payable _bank, uint256 _bankPercent) {
        bank = _bank;
        best = _best;
        bankPercent = _bankPercent;
        minEthToStartCycle = _minEthToStartCycle;
        cycles[counter.current()].startTimestamp = block.timestamp;
    }

    receive() external payable {
        require(msg.value > 0, "Nothing to receive");

        uint256 bankPart = (msg.value * bankPercent / 10000);
        if(bankPart > 0) {
            (bool success, ) = bank.call{value: bankPart}("");
            require(success, "Re-route to bank failed");
        }

        //is current cycle started a month ago?
        if(cycles[counter.current()].startTimestamp + CYCLE_DURATION < block.timestamp) {
            //is current cycle got enough royalty?
            if(cycles[counter.current()].balance >= minEthToStartCycle) {
                //before starting next cycle we calculate 'ETH per NFT' for current cycle
                cycles[counter.current()].perTokenReward = getUnitPayment(cycles[counter.current()].balance);
                //start new cycle
                counter.increment();
                cycles[counter.current()].startTimestamp = block.timestamp;
                //previous cycle already got enough royalty, otherwise we wouldn't get here, thus we assign this deposit to new cycle
                cycles[counter.current()].balance += msg.value - bankPart;
            } else {
                cycles[counter.current()].balance += msg.value - bankPart;
            }
        } else {
            cycles[counter.current()].balance += msg.value - bankPart;
        }
    }

    function setBank(address payable _bank) public {
        require(_bank != address(0), "Must not be zero-address");
        bank = _bank;
    }

    function setBankPercent(uint256 _percent) public {
        bankPercent = _percent;
    }

    // amount is the total sum that will be divided into 'per nft' pieces
    function getUnitPayment(uint256 _amount) public view returns (uint256) {
        uint256 totalDelegators = best.getTotalDelegators();
        return (totalDelegators > 0) ? (_amount / totalDelegators) : 0;
    }

    function claim(uint256[] calldata tokenIds) external payable {
        // console.log(counter.current());
        require(!lockClaim, "Reentrant call!");
        lockClaim = true;
        require(address(this).balance > 0, "No royalty");
        require(best.balanceOf(msg.sender) > 0, "You dont have NFTs");

        if(cycles[counter.current()].startTimestamp + CYCLE_DURATION < block.timestamp) {
            if(cycles[counter.current()].balance >= minEthToStartCycle) {
                cycles[counter.current()].perTokenReward = getUnitPayment(cycles[counter.current()].balance);
                counter.increment();
                cycles[counter.current()].startTimestamp = block.timestamp;
            }
        }
        require(counter.current() > 0, "Too soon");

        uint256 reward;
        // iterate over tokens that user passed
        for(uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(best.ownerOf(tokenId) == msg.sender, "Not owner");
            require(best.getDelegatee(msg.sender, tokenId) != address(0), "NFT should be delegated");

            uint256 delegationTimestamp = best.getDelegationTimestamp(tokenId);
            if(delegationTimestamp > 0) {
                // iterate over cycles
                for(uint256 o = 0; o < counter.current(); o++) {
                    if(cycles[o].perTokenReward > 0) { // reward is only set when new cycle starts, so with this check we will skip current cycle
                        if(cycles[o].isClaimed[tokenId] == false) {
                            // console.log(cycles[o].perTokenReward, delegationTimestamp, cycles[o].startTimestamp, o);
                            if(delegationTimestamp < cycles[o].startTimestamp) {
                                reward += cycles[o].perTokenReward;
                                cycles[o].isClaimed[tokenId] = true;
                            }
                        }
                    }
                }
            }
        }

        require(reward > 0, "Nothing to claim");

        (bool success, ) = payable(msg.sender).call{value: reward}("");  
        require(success, "Transfer failed");
        console.log("c:", counter.current()-1, cycles[counter.current()-1].balance, cycles[counter.current()-1].startTimestamp);
        console.log("c:", counter.current(), cycles[counter.current()].balance, cycles[counter.current()].startTimestamp);
        // console.log(cycles[counter.current()-1].perTokenReward, cycles[counter.current()-1].startTimestamp);
        lockClaim = false;
    }

}