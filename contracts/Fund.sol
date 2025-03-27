// SDPX-License-Identifier: MIT

pragma solidity ^0.8.29;

import "contracts/tokens/SystemToken.sol";
import "contracts/tokens/WrapToken.sol";

contract Fund {
    SystemToken systemToken;
    WrapToken wrapToken;
    mapping(address => bool) public daoMembers;
    mapping(uint256 => ProposalType) public proposals; 

    enum ProposalType {
        A,
        B,
        C,
        D,
        E,
        F
    }

    enum VotingStatus {
        Accepted,
        Unaccepted,
        Deleted
    }

    struct Voting {
        VotingStatus status;
        uint256 startedAt;
        uint256 endedAt;
        address initiatedBy;
        string priority;
        string quorumMechanism;
        string eventTypeAfterVoting;
    }

    // Один голос в голосовании = 3 системным токенам;
    // Wrap-токен = ½ системного токена;
    // Стоимость wrap-токена = 1 Eth

    // constructor(address _systemToken, address _wrapToken) {
    //     systemToken = SystemToken(_systemToken);
    //     wrapToken = WrapToken(_wrapToken);
    // }

    function deleteVoting() public {}

    function initiateVoting() public {}
}
