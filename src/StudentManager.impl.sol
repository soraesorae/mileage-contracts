// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ISwMileageToken} from "./ISwMileageToken.sol";
import {SwMileageTokenImpl} from "./SwMileageToken.impl.sol";
import {IStudentManager} from "./IStudentManager.sol";
import {Admin} from "./Admin.sol";

contract StudentManagerImpl is IStudentManager, Admin {
    mapping(bytes32 => address) public students;
    mapping(address => bytes32) public studentByAddr;
    mapping(uint256 => DocumentSubmission) public docSubmissions;
    mapping(uint256 => DocumentResult) public docResults;
    uint256 private documentsCount;

    mapping(bytes32 => address) public pendingAccountChanges;
    uint256 private requestsCount;

    SwMileageTokenImpl public mileageToken;

    constructor(
        SwMileageTokenImpl _mileageToken
    ) {
        mileageToken = _mileageToken;
    }

    function changeMileageToken(
        SwMileageTokenImpl addr
    ) external onlyAdmin {
        mileageToken = addr;
    }

    function getDocSubmission(
        uint256 index
    ) public view returns (DocumentSubmission memory) {
        return docSubmissions[index];
    }

    function getDocResult(
        uint256 index
    ) public view returns (DocumentResult memory) {
        return docResults[index];
    }

    function getPendingAccountChange(
        bytes32 studentId
    ) public view returns (address) {
        return pendingAccountChanges[studentId];
    }

    function hasPendingAccountChange(
        bytes32 studentId
    ) public view returns (bool) {
        return pendingAccountChanges[studentId] != address(0);
    }

    // check account is EOA
    function registerStudent(
        bytes32 studentId
    ) external {
        require(studentId != bytes32("") && students[studentId] == address(0), "studentId already exists");
        require(studentByAddr[msg.sender] == bytes32(""), "account already exists");
        students[studentId] = msg.sender;
        studentByAddr[msg.sender] = studentId;
    }

    function submitDocument(
        bytes32 docHash
    ) external returns (uint256) {
        bytes32 studentId = studentByAddr[msg.sender];
        require(studentId != "", "account doesn't exist");
        require(students[studentId] == msg.sender, "address validation check failed");
        uint256 documentIndex = documentsCount;
        docSubmissions[documentIndex] =
            DocumentSubmission({studentId: studentId, docHash: docHash, status: SubmissionStatus.Pending});
        ++documentsCount;
        emit DocSubmitted(documentIndex, studentId, docHash);
        return documentIndex;
    }

    function approveDocument(uint256 documentIndex, uint256 amount, bytes32 reasonHash) external onlyAdmin {
        DocumentSubmission storage document = docSubmissions[documentIndex];
        require(document.status == SubmissionStatus.Pending, "unavailable document");
        if (amount == 0) {
            document.status = SubmissionStatus.Rejected;
            docResults[documentIndex] = DocumentResult({reasonHash: reasonHash, amount: 0});
            emit DocRejected();
            return;
        }
        bytes32 studentId = document.studentId;
        address student = students[studentId];
        document.status = SubmissionStatus.Approved;
        mileageToken.mint(student, amount);
        docResults[documentIndex] = DocumentResult({reasonHash: reasonHash, amount: amount});

        emit DocApproved(documentIndex, studentId, amount);
    }

    function burnFrom(bytes32 studentId, address account, uint256 amount) external onlyAdmin {
        // is valid account, studentId?
        if (account == address(0)) {
            account = students[studentId];
            mileageToken.burnFrom(account, amount);
        } else {
            studentId = studentByAddr[account];
            mileageToken.burnFrom(account, amount);
        }
        emit MileageBurned(studentId, amount);
    }

    function proposeAccountChange(
        address targetAccount
    ) public {
        bytes32 studentId = studentByAddr[msg.sender];
        require(targetAccount != address(0), "invalid targetAccount");
        require(studentId != "", "account doesn't exist");
        require(students[studentId] == msg.sender, "address validation check failed");
        require(studentByAddr[targetAccount] == "", "targetAccount already exists");

        pendingAccountChanges[studentId] = targetAccount;

        emit AccountChangeProposed(studentId, targetAccount);
    }

    function confirmAccountChange(
        bytes32 studentId
    ) public {
        address currentAccount = students[studentId];
        address targetAccount = pendingAccountChanges[studentId];
        uint256 balance = 0;
        bool isParticipated = false;

        require(targetAccount != address(0), "invalid targetAccount");
        require(targetAccount == msg.sender, "unauthorized confirmation");
        require(studentByAddr[targetAccount] == "", "targetAccount already exists");

        if (mileageToken.participated(currentAccount)) {
            isParticipated = true;
            balance = mileageToken.balanceOf(currentAccount);
        }

        students[studentId] = targetAccount;
        studentByAddr[targetAccount] = studentId;

        delete pendingAccountChanges[studentId];

        if (isParticipated) {
            mileageToken.transferFrom(currentAccount, targetAccount, balance);
        }

        emit AccountChangeConfirmed(studentId, targetAccount);
        emit AccountChanged(studentId, currentAccount, targetAccount);
    }

    function changeAccount(bytes32 studentId, address targetAccount) external onlyAdmin {
        address currentAccount = students[studentId];
        uint256 balance = 0;
        bool isParticipated = false;

        if (mileageToken.participated(currentAccount)) {
            isParticipated = true;
            balance = mileageToken.balanceOf(currentAccount);
        }

        students[studentId] = targetAccount;
        studentByAddr[targetAccount] = studentId;
        if (isParticipated) {
            mileageToken.transferFrom(currentAccount, targetAccount, balance);
        }
        emit AccountChanged(studentId, currentAccount, targetAccount);
    }
}
