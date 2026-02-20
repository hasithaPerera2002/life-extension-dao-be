// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ProposalsLib } from "../libraries/ProposalsLib.sol";

interface IProposal {
    struct ProjectLinks {
        string projectLink;
        string projectImageLink;
        string projectVideoLink;
    }

    struct ProposalInput {
        string title;
        string description;
        string projectLink;
        string projectImageLink;
        string projectVideoLink;
        uint32 endDate;
    }

    struct ProposalData {
        uint64 id;
        address proposer;
        string title;
        string description;
        uint32 yesVotes;
        uint32 noVotes;
        uint32 deadlineForApproval;
        ProjectLinks projectLinks;
        ProposalsLib.ProjectStatus projectStatus;
        uint32 createdDate;
        uint32 endDate;
        ProposalsLib.ProposalStatus proposalStatus;
    }

    function getProposal(uint32 id) external view returns (ProposalData memory);
    function getProposals() external view returns (ProposalData[] memory allProposals);
    function getProposalCount() external view returns (uint32);
    function getProposalIds() external view returns (uint32[] memory ids);
    function getProposalsByStatus(ProposalsLib.ProposalStatus status) external view returns (ProposalData[] memory);
}
