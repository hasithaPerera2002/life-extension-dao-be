// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AddressManager } from "./AddressManager.sol";
import { IAddressManager } from "./interfaces/IAddressManager.sol";
import { IGovernance } from "./interfaces/IGovernance.sol";
import { IMember } from "./interfaces/IMember.sol";
import { IProposal } from "./interfaces/IProposal.sol";
import { ProposalsLib } from "./libraries/ProposalsLib.sol";

contract Proposal is IProposal {
    error ActionFailed(string reason);
    error FailedCall();
    error InsufficientBalance(uint256 balance, uint256 needed);

    AddressManager private _addressManager;
    IGovernance private _governanceContract;
    IMember private _membersContract;
    address payable private _safeAddress;
    address private _owner;

    uint64 private _proposalFee = 0.01 ether;
    uint32 private _proposalCount;
    uint32[] private _proposalIds;
    mapping(uint64 => IProposal.ProposalData) public proposals;
    mapping(address => uint256) public lastProposalTime;

    event ProposalCreated(uint64 indexed id, address indexed proposer);
    event ProposalExecuted(uint64 indexed id, bool approved);
    event VoteCast(address indexed voter, uint64 indexed proposalId, bool vote);
    event voteAddress(address indexed voter, uint64 indexed proposalId, bool vote, address memberContract);
    event PaymentSuccess(address indexed payer, uint256 amount);
    event PaymentFailed(address indexed member, uint256 amount, string reason);

    constructor(address _addressManagerAddr) {
        _addressManager = AddressManager(payable(_addressManagerAddr));
        _safeAddress = payable(_addressManagerAddr);
        _owner = msg.sender;
    }

    function addressManager() external view returns (AddressManager) {
        return _addressManager;
    }

    function governanceContract() external view returns (IGovernance) {
        return _governanceContract;
    }

    function membersContract() external view returns (IMember) {
        return _membersContract;
    }

    function safeAddress() external view returns (address payable) {
        return _safeAddress;
    }

    function proposalFee() external view returns (uint64) {
        return _proposalFee;
    }

    function setGovernanceContract(address governanceContractAddress) external {
        require(address(_addressManager.proposal()) == msg.sender || msg.sender == address(_addressManager) || msg.sender == _owner, "Only proposal, AddressManager or owner");
        _governanceContract = IGovernance(governanceContractAddress);
    }

    function setMemberContract(address memberContractAddress) external {
        require(address(_addressManager.proposal()) == msg.sender || msg.sender == address(_addressManager) || msg.sender == _owner, "Only proposal, AddressManager or owner");
        _membersContract = IMember(memberContractAddress);
    }

    function createProposal(IProposal.ProposalInput calldata input) external payable {
        require(msg.value >= _proposalFee, "Insufficient fee");
        _proposalCount++;
        uint64 id = uint64(_proposalCount);
        _proposalIds.push(uint32(id));
        proposals[id] = IProposal.ProposalData({
            id: id,
            proposer: msg.sender,
            title: input.title,
            description: input.description,
            yesVotes: 0,
            noVotes: 0,
            deadlineForApproval: 0,
            projectLinks: IProposal.ProjectLinks(input.projectLink, input.projectImageLink, input.projectVideoLink),
            projectStatus: ProposalsLib.ProjectStatus.NotStarted,
            createdDate: uint32(block.timestamp),
            endDate: input.endDate,
            proposalStatus: ProposalsLib.ProposalStatus.Active
        });
        lastProposalTime[msg.sender] = block.timestamp;
        _safeAddress.transfer(msg.value);
        emit ProposalCreated(id, msg.sender);
        emit PaymentSuccess(msg.sender, msg.value);
    }

    function voteProposal(uint32 _proposalId, bool _support) external {
        require(address(_governanceContract) != address(0), "Governance not set");
        require(address(_membersContract) != address(0), "Members not set");
        require(_membersContract.isActiveMember(msg.sender), "Not active member");
        _governanceContract.registerVote(_proposalId, msg.sender);
        emit VoteCast(msg.sender, uint64(_proposalId), _support);
        emit voteAddress(msg.sender, uint64(_proposalId), _support, address(_membersContract));
    }

    function executeProposal(uint32 id, bool result) external {
        require(address(_governanceContract) != address(0) && address(_governanceContract) == msg.sender, "Only governance can execute");
        IProposal.ProposalData storage p = proposals[uint64(id)];
        require(p.id != 0, "Proposal not found");
        p.proposalStatus = result ? ProposalsLib.ProposalStatus.Approved : ProposalsLib.ProposalStatus.Rejected;
        if (result) {
            IGovernance(_governanceContract).executeProposal(id);
        }
        emit ProposalExecuted(uint64(id), result);
    }

    function executeProject(uint32 _proposalId, bool approved) external {
        IProposal.ProposalData storage p = proposals[uint64(_proposalId)];
        require(p.proposer == msg.sender, "Only proposer can execute project");
        p.projectStatus = approved ? ProposalsLib.ProjectStatus.Completed : ProposalsLib.ProjectStatus.Cancelled;
    }

    function setProposalStatus(uint64 id, ProposalsLib.ProposalStatus status) external {
        require(address(_governanceContract) == msg.sender || proposals[id].proposer == msg.sender, "Not authorized");
        proposals[id].proposalStatus = status;
    }

    function setProjectStatus(uint32 id, ProposalsLib.ProjectStatus status) external {
        require(proposals[uint64(id)].proposer == msg.sender, "Only proposer");
        proposals[uint64(id)].projectStatus = status;
    }

    function updateProposalData(uint32 id, IProposal.ProposalInput calldata input) external payable {
        require(proposals[uint64(id)].proposer == msg.sender, "Only proposer");
        IProposal.ProposalData storage p = proposals[uint64(id)];
        p.title = input.title;
        p.description = input.description;
        p.projectLinks = IProposal.ProjectLinks(input.projectLink, input.projectImageLink, input.projectVideoLink);
        p.endDate = input.endDate;
    }

    function updateProposalEndDate(uint32 id, uint32 newEndDate) external payable {
        require(proposals[uint64(id)].proposer == msg.sender, "Only proposer");
        require(newEndDate > block.timestamp, "End date must be in future");
        proposals[uint64(id)].endDate = newEndDate;
    }

    function getProposal(uint32 id) external view returns (IProposal.ProposalData memory) {
        return proposals[uint64(id)];
    }

    function getProposals() external view returns (IProposal.ProposalData[] memory allProposals) {
        allProposals = new IProposal.ProposalData[](_proposalIds.length);
        for (uint256 i; i < _proposalIds.length; i++) {
            allProposals[i] = proposals[uint64(_proposalIds[i])];
        }
        return allProposals;
    }

    function getProposalCount() external view returns (uint32) {
        return _proposalCount;
    }

    function getProposalIds() external view returns (uint32[] memory ids) {
        return _proposalIds;
    }

    function getProposalByUser() external view returns (IProposal.ProposalData[] memory) {
        uint256 count;
        for (uint256 i; i < _proposalIds.length; i++) {
            if (proposals[uint64(_proposalIds[i])].proposer == msg.sender) count++;
        }
        IProposal.ProposalData[] memory result = new IProposal.ProposalData[](count);
        uint256 j;
        for (uint256 i; i < _proposalIds.length; i++) {
            if (proposals[uint64(_proposalIds[i])].proposer == msg.sender) {
                result[j++] = proposals[uint64(_proposalIds[i])];
            }
        }
        return result;
    }

    function getProposalsByStatus(ProposalsLib.ProposalStatus status) external view returns (IProposal.ProposalData[] memory) {
        uint256 count;
        for (uint256 i; i < _proposalIds.length; i++) {
            if (proposals[uint64(_proposalIds[i])].proposalStatus == status) count++;
        }
        IProposal.ProposalData[] memory result = new IProposal.ProposalData[](count);
        uint256 j;
        for (uint256 i; i < _proposalIds.length; i++) {
            if (proposals[uint64(_proposalIds[i])].proposalStatus == status) {
                result[j++] = proposals[uint64(_proposalIds[i])];
            }
        }
        return result;
    }
}
