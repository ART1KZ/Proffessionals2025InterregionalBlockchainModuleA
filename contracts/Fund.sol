// SDPX-License-Identifier: MIT

pragma solidity ^0.8.29;

import "contracts/GovernanceBundle.sol";
import "contracts/tokens/SystemToken.sol";
import "contracts/tokens/WrapToken.sol";


contract SimpleGovernor is Governor, GovernorCountingSimple {
    // Типы предложений
    enum ProposalType { A, B, C, D, E, F }
    // Механизмы кворума
    enum QuorumMechanism { SimpleMajority, SuperMajority, Weighted }
    // Статусы голосования
    enum VoteStatus { Active, Succeeded, Defeated, Canceled }

    // Структура для хранения данных предложения
    struct ProposalData {
        ProposalType proposalType;
        QuorumMechanism quorumMechanism;
        VoteStatus status;
        uint256 startTime;
        uint256 endTime;
        address proposer;
        uint256 priority; // Приоритет (например, 1-10)
        address startupAddress; // Для типов A и B
        uint256 investmentAmount; // Для типов A и B
    }

    // Системный токен и Wrap-токен
    ERC20 public systemToken;
    ERC20 public wrapToken;

    // Участники DAO
    mapping(address => bool) public isMember;
    address[] public members;

    // Хранение предложений
    mapping(uint256 => ProposalData) public proposalData;

    // Отслеживание голосов
    mapping(uint256 => mapping(address => uint256)) public votesCast;

    constructor(
        ERC20 _systemToken,
        ERC20 _wrapToken,
        address[] memory initialMembers
    ) Governor("SimpleGovernor") {
        systemToken = _systemToken;
        wrapToken = _wrapToken;
        for (uint256 i = 0; i < initialMembers.length; i++) {
            isMember[initialMembers[i]] = true;
            members.push(initialMembers[i]);
        }
    }

    // Покупка Wrap-токена за ETH (1 Wrap = 1 ETH)
    function buyWrapToken() external payable {
        require(msg.value >= 1 ether, "Send at least 1 ETH");
        uint256 wrapAmount = msg.value / 1 ether; // 1 ETH = 1 Wrap
        require(wrapToken.transfer(msg.sender, wrapAmount * 1e18), "Transfer failed");
    }

    // Делегирование голоса через Wrap-токены
    function delegateVote(uint256 proposalId, uint256 wrapAmount) external {
        require(proposalData[proposalId].status == VoteStatus.Active, "Voting not active");
        require(wrapToken.transferFrom(msg.sender, address(this), wrapAmount), "Transfer failed");
        // Wrap-токены добавляют вес к голосу (1 Wrap = 1/6 голоса)
        votesCast[proposalId][msg.sender] += wrapAmount / 6;
    }

    // Инициализация предложения
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        ProposalType proposalType,
        QuorumMechanism quorumMechanism,
        uint256 priority,
        address startupAddress, // Для A и B
        uint256 investmentAmount // Для A и B
    ) public returns (uint256) {
        require(isMember[msg.sender], "Only members can propose");
        require(
            (proposalType == ProposalType.A && quorumMechanism == QuorumMechanism.Weighted) ||
            (proposalType == ProposalType.B && quorumMechanism == QuorumMechanism.Weighted) ||
            (proposalType == ProposalType.C && (quorumMechanism == QuorumMechanism.SimpleMajority || quorumMechanism == QuorumMechanism.SuperMajority)) ||
            (proposalType == ProposalType.D && (quorumMechanism == QuorumMechanism.SimpleMajority || quorumMechanism == QuorumMechanism.SuperMajority)) ||
            (proposalType == ProposalType.E && (quorumMechanism == QuorumMechanism.SimpleMajority || quorumMechanism == QuorumMechanism.SuperMajority)) ||
            (proposalType == ProposalType.F && (quorumMechanism == QuorumMechanism.SimpleMajority || quorumMechanism == QuorumMechanism.SuperMajority)),
            "Invalid quorum mechanism for proposal type"
        );

        uint256 proposalId = super.propose(targets, values, calldatas, description);
        proposalData[proposalId] = ProposalData({
            proposalType: proposalType,
            quorumMechanism: quorumMechanism,
            status: VoteStatus.Active,
            startTime: block.timestamp + votingDelay(),
            endTime: block.timestamp + votingDelay() + votingPeriod(),
            proposer: msg.sender,
            priority: priority,
            startupAddress: startupAddress,
            investmentAmount: investmentAmount
        });
        return proposalId;
    }

    // Удаление предложения
    function cancelProposal(uint256 proposalId) external {
        ProposalData storage data = proposalData[proposalId];
        require(msg.sender == data.proposer, "Only proposer can cancel");
        require(data.status == VoteStatus.Active, "Proposal not active");
        data.status = VoteStatus.Canceled;
        _cancel(data.startupAddress, new uint256[](0), new bytes[](0), keccak256(abi.encodePacked(proposalId)));
    }

    // Голосование
    function castVote(uint256 proposalId, uint8 support) public override returns (uint256) {
        require(isMember[msg.sender], "Only members can vote");
        require(proposalData[proposalId].status == VoteStatus.Active, "Voting not active");
        uint256 systemBalance = systemToken.balanceOf(msg.sender);
        uint256 weight = (systemBalance / 3) + votesCast[proposalId][msg.sender]; // 1 голос = 3 токена + Wrap-вес
        votesCast[proposalId][msg.sender] = weight;
        return super.castVoteWithReason(proposalId, support, "");
    }

    // Проверка успеха голосования
    function _voteSucceeded(uint256 proposalId) 
        internal 
        view 
        override(Governor, GovernorCountingSimple) 
        returns (bool) 
    {
        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = proposalVotes(proposalId);
        ProposalData memory data = proposalData[proposalId];
        uint256 totalSupply = systemToken.totalSupply();
        uint256 totalVotes = members.length; // Общее число участников

        if (data.quorumMechanism == QuorumMechanism.Weighted) {
            return forVotes >= (totalSupply * 10) / 100; // 10% токенов для A и B
        } else if (data.quorumMechanism == QuorumMechanism.SimpleMajority) {
            return forVotes >= (totalVotes * 50) / 100 + 1; // 50% + 1 голос
        } else if (data.quorumMechanism == QuorumMechanism.SuperMajority) {
            return forVotes >= (totalVotes * 2) / 3; // 2/3 голосов
        }
        return forVotes > againstVotes; // По умолчанию
    }

    // Стандартные функции Governor
    function votingDelay() public pure override returns (uint256) {
        return 1;
    }

    function votingPeriod() public pure override returns (uint256) {
        return 50400;
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 0;
    }

    function quorum(uint256) public pure override returns (uint256) {
        return 0;
    }

    function state(uint256 proposalId)
        public
        view
        override
        returns (ProposalState)
    {
        return super.state(proposalId);
    }
}