// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IStudentManager {
    struct DocumentSubmission {
        SubmissionStatus status;
        bytes32 studentId;
        bytes32 docHash;
    }

    struct DocumentResult {
        bytes32 reasonHash;
        uint256 amount;
    }

    enum SubmissionStatus {
        NotExists,
        Pending,
        Approved,
        Rejected
    }

    event DocSubmitted(uint256 indexed index, bytes32 indexed studentId, bytes32 docHash);
    event DocApproved(uint256 indexed index, bytes32 indexed studentId, uint256 amount);
    event DocRejected();

    event AccountChangeProposed(bytes32 indexed studentId, address targetAccount);
    event AccountChangeConfirmed(bytes32 indexed studentId, address targetAccount);

    event AccountChanged(bytes32 indexed studentId, address previous, address current);

    event MileageBurned(bytes32 indexed studentId, uint256 amount);
}
