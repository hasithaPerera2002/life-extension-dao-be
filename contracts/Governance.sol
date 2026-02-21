// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AddressManager } from "./AddressManager.sol";
import { IAddressManager } from "./interfaces/IAddressManager.sol";
import { IGovernance } from "./interfaces/IGovernance.sol";
import { IMember } from "./interfaces/IMember.sol";
import { IProposal } from "./interfaces/IProposal.sol";
import { IPayouts } from "./interfaces/IPayouts.sol";

contract Governance is IGovernance {
    error ActionFailed(string reason);

    AddressManager private _addressManager;
    address private _owner;
    IMember private _memberContract;
    IProposal private _proposalContract;
    IPayouts private _payoutsContract;

    mapping(uint32 => mapping(address => bool)) private _hasVoted;
    mapping(uint32 => mapping(address => bool)) private _hasClaimed;
    mapping(uint32 => bool) private _proposalCompleted;

    event VoteCast(address indexed voter, uint32 indexed proposalId, bool vote);
    event ProposalExecuted(uint32 indexed id, bool approved);
    event Claimed(uint32 proposalId, address member, uint256 amount);
    event Debug(string message);
    event DebugAddress(address addr);
    event DebugValue(uint256 value);

    constructor(address _addressManagerAddr) {
        _addressManager = AddressManager(payable(_addressManagerAddr));
        _owner = msg.sender;
    }

    function addressManager() external view returns (AddressManager) {
        return _addressManager;
    }

    function memberContract() external view returns (IMember) {
        return _memberContract;
    }

    function proposalContract() external view returns (IProposal) {
        return _proposalContract;
    }

    function payoutsContract() external view returns (IPayouts) {
        return _payoutsContract;
    }

    function hasVoted(uint32 proposalId, address account) external view returns (bool) {
        return _hasVoted[proposalId][account];
    }

    function hasClaimed(uint32 proposalId, address account) external view returns (bool) {
        return _hasClaimed[proposalId][account];
    }

    function proposalCompleted(uint32 proposalId) external view returns (bool) {
        return _proposalCompleted[proposalId];
    }

    function isVoted(uint32 _proposalId, address _member) external view returns (bool) {
        return _hasVoted[_proposalId][_member];
    }

    function getVotingPower(address, uint32) external pure returns (uint256) {
        return 1;
    }

    function setMemberContract(address _memberContractAddr) external {
        require(
            address(_addressManager.member()) == msg.sender || msg.sender == _owner,
            "Only member contract or owner"
        );
        _memberContract = IMember(_memberContractAddr);
    }

    function setProposalContract(address _proposalContractAddr) external {
        require(
            address(_addressManager.proposal()) == msg.sender || msg.sender == _owner,
            "Only proposal contract or owner"
        );
        _proposalContract = IProposal(_proposalContractAddr);
    }

    function setPayoutsContract(address _payoutsContractAddr) external {
        require(
            address(_addressManager.payouts()) == msg.sender || msg.sender == _owner,
            "Only payouts contract or owner"
        );
        _payoutsContract = IPayouts(_payoutsContractAddr);
    }

    function registerVote(uint32 _proposalId, address _member) external {
        require(address(_proposalContract) == msg.sender, "Only proposal contract can register votes");
        require(_memberContract.isActiveMember(_member), "No active members");
        require(!_hasVoted[_proposalId][_member], "Already voted");
        _hasVoted[_proposalId][_member] = true;
        emit VoteCast(_member, _proposalId, true);
    }

    function executeProposal(uint32 _proposalId) external {
        require(address(_proposalContract) != address(0), "Proposal contract not set");
        IProposal.ProposalData memory p = _proposalContract.getProposal(_proposalId);
        require(p.proposer == msg.sender || address(_proposalContract) == msg.sender, "Only proposer or proposal contract can execute");
        require(!_proposalCompleted[_proposalId], "Proposal already executed");
        _proposalCompleted[_proposalId] = true;
        emit ProposalExecuted(_proposalId, true);
    }

    function setIsClaimed(uint32 _proposalId, address _member, bool _status, uint256 _totalPaid) external {
        require(address(_payoutsContract) == msg.sender, "Only payouts contract can set claim");
        _hasClaimed[_proposalId][_member] = _status;
        if (_status) emit Claimed(_proposalId, _member, _totalPaid);
    }

    function claim(uint32 _proposalId) external {
        require(!_hasClaimed[_proposalId][msg.sender], "Already claimed");
        require(_proposalCompleted[_proposalId], "Proposal not executed");
        _hasClaimed[_proposalId][msg.sender] = true;
        uint256 amount = 1; // voting power per member; getVotingPower(msg.sender, _proposalId) for full logic
        emit Claimed(_proposalId, msg.sender, amount);
        // Actual transfer would be done by payouts contract
    }
}
