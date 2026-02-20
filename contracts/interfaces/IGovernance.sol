// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IGovernance {
    function registerVote(uint32 _proposalId, address _member) external;
    function executeProposal(uint32 _proposalId) external;
    function getVotingPower(address member, uint32 _proposalId) external view returns (uint256);
    function isVoted(uint32 _proposalId, address _member) external view returns (bool);
    function hasVoted(uint32, address) external view returns (bool);
    function hasClaimed(uint32, address) external view returns (bool);
    function proposalCompleted(uint32) external view returns (bool);
    function setIsClaimed(uint32 _proposalId, address _member, bool _status, uint256 _totalPaid) external;
    function claim(uint32 _proposalId) external;
    function setMemberContract(address _memberContract) external;
    function setProposalContract(address _proposalContract) external;
    function setPayoutsContract(address _payoutsContract) external;
}
