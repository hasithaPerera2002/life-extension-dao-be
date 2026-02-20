// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMember {
    struct Payment {
        uint32 timestamp;
        uint256 amount;
    }

    struct Insurance {
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
        Payment[] paymentHistory;
        bool isRequestForClaim;
        bool isClaimed;
    }

    struct Member {
        address memberAddress;
        uint32 joinDate;
        bool isActive;
        bool isSlashed;
        uint32 votesCast;
        uint32[] proposals;
        Insurance[] insurances;
    }

    function getMemberInfo(address memberAddress) external view returns (Member memory);
    function getInsuranceInfo(address memberAddress, uint32 insuranceId) external view returns (Insurance memory);
    function isMember(address memberAddress) external view returns (bool);
    function isActiveMember(address memberAddress) external view returns (bool);
    function getActiveMemberCount() external view returns (uint32 activeCount);
}
