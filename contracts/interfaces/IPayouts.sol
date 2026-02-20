// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPayouts {
    struct PayoutData {
        uint32 proposalId;
        address member;
        uint256 amount;
        uint256 timestamp;
        bool claimed;
        uint256 claimTimestamp;
    }

    function getPayoutData() external view returns (PayoutData[] memory);
    function getMemberPayouts() external view returns (PayoutData[] memory);
    function checkEligibility(uint32 _proposalId, address _member) external view returns (bool);
    function setPayoutData(uint32 _proposalId, address _member, uint256 _amount) external;
    function setPayoutStatus(uint32 _proposalId, address _member, bool _status, uint256 _amount) external;
}
