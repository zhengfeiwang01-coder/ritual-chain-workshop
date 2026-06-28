// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PrecompileConsumer} from "./utils/PrecompileConsumer.sol";

contract AIJudge is PrecompileConsumer {

    uint256 public constant MAX_SUBMISSIONS = 10;
    uint256 public constant MAX_ANSWER_LENGTH = 2000;

    uint256 public nextBountyId = 1;

    struct BountyInfo {
        address creator;
        string title;
        string rubric;
        uint256 reward;
        uint256 submitDeadline;
        uint256 revealDeadline;
        bool judged;
        bool finalized;
        bytes judgmentResult;
        uint256 winnerIndex;
    }

    struct ParticipantSubmission {
        bytes32 commitment;
        string answer;
        bool revealed;
    }

    mapping(uint256 => BountyInfo) public bounties;
    mapping(uint256 => mapping(address => ParticipantSubmission)) public submissions;
    mapping(uint256 => mapping(address => bool)) public hasCommitted;

    event BountyCreated(
        uint256 indexed bountyId,
        address indexed creator,
        string title,
        uint256 reward,
        uint256 submitDeadline,
        uint256 revealDeadline
    );

    event CommitmentMade(uint256 indexed bountyId, address indexed participant);
    event AnswerRevealed(uint256 indexed bountyId, address indexed participant);
    event BountyJudged(uint256 indexed bountyId);
    event WinnerFinalized(uint256 indexed bountyId, address indexed winner, uint256 reward);

    modifier onlyCreator(uint256 bountyId) {
        require(msg.sender == bounties[bountyId].creator, "Only creator can call");
        _;
    }

    function createBounty(
        string calldata title,
        string calldata rubric,
        uint256 submitDeadline,
        uint256 revealDeadline
    ) external payable returns (uint256 bountyId) {
        require(msg.value > 0, "Reward required");
        require(submitDeadline > block.timestamp, "Invalid submit deadline");
        require(revealDeadline > submitDeadline, "Invalid reveal deadline");

        bountyId = nextBountyId++;

        bounties[bountyId] = BountyInfo({
            creator: msg.sender,
            title: title,
            rubric: rubric,
            reward: msg.value,
            submitDeadline: submitDeadline,
            revealDeadline: revealDeadline,
