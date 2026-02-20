// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AddressManager } from "./AddressManager.sol";
import { IAddressManager } from "./interfaces/IAddressManager.sol";
import { IGovernance } from "./interfaces/IGovernance.sol";
import { IMember } from "./interfaces/IMember.sol";
import { IProposal } from "./interfaces/IProposal.sol";
import { IPayouts } from "./interfaces/IPayouts.sol";
import { ProposalsLib } from "./libraries/ProposalsLib.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Members is IMember, ReentrancyGuard {
    error ActionFailed(string reason);
    error FailedCall();
    error InsufficientBalance(uint256 balance, uint256 needed);

    AddressManager private _addressManager;
    address private _owner;
    IGovernance private _governanceContract;
    IProposal private _proposalContract;
    IPayouts private _payoutsContract;
    address payable private _safeAddress;

    struct MemberData {
        address memberAddress;
        uint32 joinDate;
        bool isActive;
        bool isSlashed;
        uint32 votesCast;
    }

    mapping(address => MemberData) public members;
    address[] public memberList;
    mapping(address => uint32[]) private _memberProposals;

    struct InsuranceData {
        uint32 insuranceId;
        uint256 installmentFee;
        uint32 startDate;
        uint256 totalPaid;
        uint256 monthsPaid;
        uint256 monthsToBePaid;
        uint32 lastPaymentDate;
        uint32 nextPaymentDate;
        uint256 dues;
        uint256 lastPaymentAmount;
        uint256 additionalBalance;
        uint256 stakedAmount;
        bool isRequestForClaim;
        bool isClaimed;
    }
    mapping(address => mapping(uint32 => InsuranceData)) private _insurances;
    mapping(address => mapping(uint32 => Payment[])) private _insurancePaymentHistory;
    mapping(address => uint32[]) private _memberInsuranceIds;

    uint256 public constant MIN_JOIN_FEE = 0.001 ether;

    event Log(string message);
    event MemberJoined(address indexed member, uint256 amountPaid, uint256 joinDate);
    event InsuranceAdded(address indexed member, uint32 insuranceId, uint256 amount);
    event InsurancePaymentUpdated(address indexed member, uint32 insuranceId, uint256 paidAmount, uint32 timestamp);
    event ProposalAdded(address indexed member, uint32 proposalId);
    event Debug(string message);

    constructor(address _addressManagerAddr, address _ownerAddr) {
        _addressManager = AddressManager(payable(_addressManagerAddr));
        _owner = _ownerAddr;
        _safeAddress = payable(_ownerAddr);
    }

    function addressManager() external view returns (AddressManager) {
        return _addressManager;
    }

    function governanceContract() external view returns (IGovernance) {
        return _governanceContract;
    }

    function proposalContract() external view returns (IProposal) {
        return _proposalContract;
    }

    function payoutsContract() external view returns (IPayouts) {
        return _payoutsContract;
    }

    function safeAddress() external view returns (address payable) {
        return _safeAddress;
    }

    function isOwner() external view returns (bool) {
        return msg.sender == _owner;
    }

    function setGovernanceContract(address _governanceContractAddr) external {
        require(address(_addressManager.governance()) == msg.sender || msg.sender == _owner, "Only governance or owner");
        _governanceContract = IGovernance(_governanceContractAddr);
    }

    function setProposalContract(address _proposalContractAddr) external {
        require(address(_addressManager.proposal()) == msg.sender || msg.sender == _owner, "Only proposal or owner");
        _proposalContract = IProposal(_proposalContractAddr);
    }

    function setPayoutsContract(address _payoutsContractAddr) external {
        require(address(_addressManager.payouts()) == msg.sender || msg.sender == _owner, "Only payouts or owner");
        _payoutsContract = IPayouts(_payoutsContractAddr);
    }

    /// Called by owner after deployment to set refs on Governance (must be called from Members so Governance accepts)
    function bootstrapGovernance(address governanceAddr, address proposalAddr, address payoutsAddr) external {
        require(msg.sender == _owner, "Only owner");
        IGovernance(governanceAddr).setMemberContract(address(this));
        IGovernance(governanceAddr).setProposalContract(proposalAddr);
        IGovernance(governanceAddr).setPayoutsContract(payoutsAddr);
    }

    function isMember(address memberAddress) external view returns (bool) {
        return members[memberAddress].memberAddress != address(0);
    }

    function isActiveMember(address memberAddress) external view returns (bool) {
        return members[memberAddress].isActive;
    }

    function getActiveMemberCount() external view returns (uint32 activeCount) {
        uint32 count;
        for (uint256 i; i < memberList.length; i++) {
            if (members[memberList[i]].isActive) count++;
        }
        return count;
    }

    function joinDAO() external payable nonReentrant {
        require(msg.value >= MIN_JOIN_FEE, "Insufficient payment");
        require(members[msg.sender].memberAddress == address(0), "Already member");
        members[msg.sender] = MemberData({
            memberAddress: msg.sender,
            joinDate: uint32(block.timestamp),
            isActive: true,
            isSlashed: false,
            votesCast: 0
        });
        memberList.push(msg.sender);
        _safeAddress.transfer(msg.value);
        emit MemberJoined(msg.sender, msg.value, block.timestamp);
    }

    function addInsurance(uint32 _insuranceId) external payable nonReentrant {
        require(members[msg.sender].isActive, "Not active member");
        require(msg.value >= 0.001 ether, "Insufficient payment");
        require(_insurances[msg.sender][_insuranceId].insuranceId == 0, "Insurance already exists");
        _insurances[msg.sender][_insuranceId] = InsuranceData({
            insuranceId: _insuranceId,
            installmentFee: msg.value,
            startDate: uint32(block.timestamp),
            totalPaid: msg.value,
            monthsPaid: 1,
            monthsToBePaid: 0,
            lastPaymentDate: uint32(block.timestamp),
            nextPaymentDate: uint32(block.timestamp + 30 days),
            dues: 0,
            lastPaymentAmount: msg.value,
            additionalBalance: 0,
            stakedAmount: 0,
            isRequestForClaim: false,
            isClaimed: false
        });
        _insurancePaymentHistory[msg.sender][_insuranceId].push(Payment(uint32(block.timestamp), msg.value));
        _memberInsuranceIds[msg.sender].push(_insuranceId);
        _safeAddress.transfer(msg.value);
        emit InsuranceAdded(msg.sender, _insuranceId, msg.value);
    }

    function addProposal(uint32 _proposalId) external returns (bool) {
        require(members[msg.sender].isActive, "Not active member");
        _memberProposals[msg.sender].push(_proposalId);
        members[msg.sender].votesCast++;
        emit ProposalAdded(msg.sender, _proposalId);
        return true;
    }

    function updateInsurancePayment(uint32 insuranceId) external payable nonReentrant returns (bool, string memory) {
        require(members[msg.sender].isActive, "Not active member");
        InsuranceData storage ins = _insurances[msg.sender][insuranceId];
        require(ins.insuranceId != 0, "Insurance not found");
        ins.totalPaid += msg.value;
        ins.monthsPaid++;
        ins.lastPaymentDate = uint32(block.timestamp);
        ins.lastPaymentAmount = msg.value;
        _insurancePaymentHistory[msg.sender][insuranceId].push(Payment(uint32(block.timestamp), msg.value));
        _safeAddress.transfer(msg.value);
        emit InsurancePaymentUpdated(msg.sender, insuranceId, msg.value, uint32(block.timestamp));
        return (true, "Payment updated successfully");
    }

    function setIsClaimed(address memberAddress, uint32 insuranceId, bool isClaimed) external {
        require(address(_payoutsContract) == msg.sender || address(_addressManager.payouts()) == msg.sender, "Only payouts");
        _insurances[memberAddress][insuranceId].isClaimed = isClaimed;
    }

    function setIsRequestForClaim(address memberAddress, uint32 insuranceId, bool isRequestForClaim) external {
        require(address(_payoutsContract) == msg.sender || address(_addressManager.payouts()) == msg.sender, "Only payouts");
        _insurances[memberAddress][insuranceId].isRequestForClaim = isRequestForClaim;
    }

    function getMemberInfo(address memberAddress) external view returns (Member memory m) {
        MemberData storage d = members[memberAddress];
        m.memberAddress = d.memberAddress;
        m.joinDate = d.joinDate;
        m.isActive = d.isActive;
        m.isSlashed = d.isSlashed;
        m.votesCast = d.votesCast;
        m.proposals = _memberProposals[memberAddress];
        uint32[] memory ids = _memberInsuranceIds[memberAddress];
        m.insurances = new Insurance[](ids.length);
        for (uint256 i; i < ids.length; i++) {
            m.insurances[i] = _toInsurance(_insurances[memberAddress][ids[i]], memberAddress, ids[i]);
        }
        return m;
    }

    function getInsuranceInfo(address memberAddress, uint32 insuranceId) external view returns (Insurance memory) {
        return _toInsurance(_insurances[memberAddress][insuranceId], memberAddress, insuranceId);
    }

    function getMemberInsurance(address memberAddress, uint32 insuranceId) external view returns (Insurance memory) {
        return _toInsurance(_insurances[memberAddress][insuranceId], memberAddress, insuranceId);
    }

    function getMemberInsurances() external view returns (Insurance[] memory) {
        uint32[] memory ids = _memberInsuranceIds[msg.sender];
        Insurance[] memory arr = new Insurance[](ids.length);
        for (uint256 i; i < ids.length; i++) {
            arr[i] = _toInsurance(_insurances[msg.sender][ids[i]], msg.sender, ids[i]);
        }
        return arr;
    }

    function getProposals() external view returns (IProposal.ProposalData[] memory) {
        if (address(_proposalContract) == address(0)) return new IProposal.ProposalData[](0);
        return _proposalContract.getProposals();
    }

    function _toInsurance(InsuranceData storage d, address memberAddress, uint32 insuranceId) internal view returns (Insurance memory out) {
        Payment[] storage histStorage = _insurancePaymentHistory[memberAddress][insuranceId];
        uint256 n = histStorage.length;
        Payment[] memory hist = new Payment[](n);
        for (uint256 i; i < n; i++) hist[i] = histStorage[i];
        out = Insurance({
            insuranceId: d.insuranceId,
            installmentFee: d.installmentFee,
            startDate: d.startDate,
            totalPaid: d.totalPaid,
            monthsPaid: d.monthsPaid,
            monthsToBePaid: d.monthsToBePaid,
            lastPaymentDate: d.lastPaymentDate,
            nextPaymentDate: d.nextPaymentDate,
            dues: d.dues,
            lastPaymentAmount: d.lastPaymentAmount,
            additionalBalance: d.additionalBalance,
            stakedAmount: d.stakedAmount,
            paymentHistory: hist,
            isRequestForClaim: d.isRequestForClaim,
            isClaimed: d.isClaimed
        });
    }
}
