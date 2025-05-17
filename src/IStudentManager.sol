// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IStudentManager {
    struct DocumentSubmission {
        bytes32 studentId;
        bytes32 docHash;
        uint256 createdAt;
        SubmissionStatus status;
    }

    struct AccountChangeProposal {
        address targetAccount;
        uint256 createdAt;
    }

    struct DocumentResult {
        bytes32 reasonHash;
        uint256 amount;
        uint256 processedAt;
    }

    enum SubmissionStatus {
        Pending,
        Approved,
        Rejected
    }

    event DocSubmitted(uint256 indexed documentIndex, bytes32 indexed studentId, bytes32 docHash);
    event DocApproved(uint256 indexed documentIndex, bytes32 indexed studentId, uint256 amount);
    event DocRejected(uint256 indexed documentIndex, bytes32 indexed studentId, bytes32 reasonHash);

    event AccountChangeProposed(bytes32 indexed studentId, address indexed account, address indexed targetAccount);
    event AccountChangeConfirmed(bytes32 indexed studentId, address indexed account, address indexed targetAccount);

    event AccountChanged(bytes32 indexed studentId, address indexed account, address indexed targetAccount);

    event MileageBurned(bytes32 indexed studentId, address indexed account, address indexed admin, uint256 amount);

    event StudentRecordUpdated(bytes32 indexed studentId, address indexed account, address indexed targetAccount);

    event transferMileageToken(bytes32 indexed fromStudentId, bytes32 indexed toStudentId, uint256 amount);

    function changeMileageToken(
        address addr
    ) external;

    function getDocSubmission(
        uint256 documentIndex
    ) external view returns (DocumentSubmission memory);

    function getDocResult(
        uint256 documentIndex
    ) external view returns (DocumentResult memory);

    function getPendingAccountChange(
        bytes32 studentId
    ) external view returns (AccountChangeProposal memory);

    function getPendingAccountChangeTarget(
        bytes32 studentId
    ) external view returns (address);

    function hasPendingAccountChange(
        bytes32 studentId
    ) external view returns (bool);

    function registerStudent(
        bytes32 studentId
    ) external;

    function submitDocument(
        bytes32 docHash
    ) external returns (uint256);

    function approveDocument(uint256 documentIndex, uint256 amount, bytes32 reasonHash) external;

    function burnFrom(bytes32 studendtId, address account, uint256 amount) external;

    function proposeAccountChange(
        address targetAccount
    ) external;

    function confirmAccountChange(
        bytes32 studentId
    ) external;

    function changeAccount(bytes32 studentId, address targetAccount) external;
    function updateStudentRecord(bytes32 studentId, address targetAccount, bool _clear) external;
    function transferFromToken(bytes32 fromStudentId, bytes32 toStudentId, uint256 amount) external;
}
