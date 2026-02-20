// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AddressManager } from "./AddressManager.sol";
import { IAddressManager } from "./interfaces/IAddressManager.sol";
import { IGovernance } from "./interfaces/IGovernance.sol";
import { IMember } from "./interfaces/IMember.sol";
import { IProposal } from "./interfaces/IProposal.sol";
import { IPayouts } from "./interfaces/IPayouts.sol";

contract Payouts is IPayouts {
    error ActionFailed(string reason);

    AddressManager private _addressManager;
    address private _owner;
    IGovernance private _governanceContract;
    IMember private _memberContract;
    IProposal private _proposalContract;

    PayoutData[] public payouts;
    uint256 public totalPayouts;

    mapping(uint32 => mapping(address => uint256)) private _payoutIndex;

    event PayoutExecuted(uint256 indexed proposalId);

    constructor(address _addressManagerAddr, address _ownerAddr) {
        _addressManager = AddressManager(payable(_addressManagerAddr));
        _owner = _ownerAddr;
    }

    function addressManager() external view returns (AddressManager) {
        return _addressManager;
    }

    function governanceContract() external view returns (IGovernance) {
        return _governanceContract;
    }

    function memberContract() external view returns (IMember) {
        return _memberContract;
    }

    function proposalContract() external view returns (IProposal) {
        return _proposalContract;
    }

    function setGovernanceContract(address _governanceContractAddr) external {
        require(msg.sender == _owner || msg.sender == address(_addressManager), "Only owner or AddressManager");
        _governanceContract = IGovernance(_governanceContractAddr);
    }

    function setMemberContract(address _memberContractAddr) external {
        require(msg.sender == _owner || msg.sender == address(_addressManager), "Only owner or AddressManager");
        _memberContract = IMember(_memberContractAddr);
    }

    function setProposalContract(address _proposalContractAddr) external {
        require(msg.sender == _owner || msg.sender == address(_addressManager), "Only owner or AddressManager");
        _proposalContract = IProposal(_proposalContractAddr);
    }

    function setPayoutData(uint32 _proposalId, address _member, uint256 _amount) external {
        require(address(_governanceContract) == msg.sender, "Only governance can set payout");
        payouts.push(PayoutData({
            proposalId: _proposalId,
            member: _member,
            amount: _amount,
            timestamp: block.timestamp,
            claimed: false,
            claimTimestamp: 0
        }));
        _payoutIndex[_proposalId][_member] = payouts.length;
        totalPayouts++;
        emit PayoutExecuted(_proposalId);
    }

    function setPayoutStatus(uint32 _proposalId, address _member, bool _status, uint256 _amount) external {
        require(address(_governanceContract) == msg.sender, "Only governance");
        uint256 idx = _payoutIndex[_proposalId][_member];
        require(idx > 0, "Payout not found");
        payouts[idx - 1].claimed = _status;
        if (_status) payouts[idx - 1].claimTimestamp = block.timestamp;
    }

    function checkEligibility(uint32 _proposalId, address _member) external view returns (bool) {
        if (address(_governanceContract) == address(0)) return false;
        return _governanceContract.hasVoted(_proposalId, _member) && !_governanceContract.hasClaimed(_proposalId, _member);
    }

    function getPayoutData() external view returns (PayoutData[] memory) {
        return payouts;
    }

    function getMemberPayouts() external view returns (PayoutData[] memory) {
        uint256 count;
        for (uint256 i; i < payouts.length; i++) {
            if (payouts[i].member == msg.sender) count++;
        }
        PayoutData[] memory result = new PayoutData[](count);
        uint256 j;
        for (uint256 i; i < payouts.length; i++) {
            if (payouts[i].member == msg.sender) result[j++] = payouts[i];
        }
        return result;
    }
}
