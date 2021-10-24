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
    uint256 private lastDepositTimestamp;
    bool private lockClaim;

    struct Cycle {
        uint256 startTimestamp;
        uint256 perTokenReward;
        mapping(uint256 => bool) isClaimed;
    }

    mapping(uint256 => Cycle) private cycles;

    constructor(Best _best, address payable _bank, uint256 _bankPercent) {
        bank = _bank;
        best = _best;
        bankPercent = _bankPercent;
    }

    receive() external payable {
        require(block.timestamp >= lastDepositTimestamp + 4 weeks, "Cant deposit twice a month");
        lastDepositTimestamp = block.timestamp;
        if(msg.value > 0) {
            uint256 bankPart = (msg.value * bankPercent / 10000);
            if(bankPart > 0) {
                (bool success, ) = bank.call{value: msg.value * bankPercent / 10000}("");
                require(success, "Re-route to bank failed");
            }
            cycles[counter.current()].perTokenReward = getUnitPayment(msg.value - bankPart);
            cycles[counter.current()].startTimestamp = block.timestamp;
            counter.increment();
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
        if(totalDelegators > 0)
            return _amount / totalDelegators;
        return 0;
    }

    function claim(uint256[] calldata tokenIds) external payable {
        require(!lockClaim, "Reentrant call!");
        lockClaim = true;
        require(address(this).balance > 0, "No royalty");
        require(best.balanceOf(msg.sender) > 0, "Not own anything");
        require(counter.current() > 0, "Too soon");
        // require(lastDepositTimestamp + 4 weeks < block.timestamp, "Royalty deposit is too young");

        uint256 reward;
        // iterate over tokens that user passed
        for(uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(best.ownerOf(tokenId) == msg.sender, "Not owner");
            require(best.getDelegatee(msg.sender, tokenId) != address(0), "Not delegated");

            uint256 delegationTimestamp = best.getDelegationTimestamp(tokenId);
            if(delegationTimestamp > 0) {
                // iterate over cycles
                for(uint256 o = 0; o < counter.current(); o++) {
                    if(cycles[o].isClaimed[tokenId] == false) {
                        if(delegationTimestamp + 4 weeks <= cycles[o].startTimestamp) {
                            reward += cycles[o].perTokenReward;
                            cycles[o].isClaimed[tokenId] = true;
                        }
                    }
                }
            }
        }

        require(reward > 0, "Nothing to claim");

        (bool success, ) = payable(msg.sender).call{value: reward}("");  
        require(success, "Transfer failed");
        lockClaim = false;
    }

}