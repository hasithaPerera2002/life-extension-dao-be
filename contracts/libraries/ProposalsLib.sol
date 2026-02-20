// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library ProposalsLib {
    enum ProposalStatus {
        Pending,
        Active,
        Approved,
        Rejected,
        Executed
    }

    enum ProjectStatus {
        NotStarted,
        InProgress,
        Completed,
        Cancelled
    }
}
