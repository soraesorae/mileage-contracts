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

    mapping(uint256 => AccountChangeRequest) public accountChangeRequests;
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

    function getAccountChangeRequest(
        uint256 index
    ) public view returns (AccountChangeRequest memory) {
        return accountChangeRequests[index];
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
        require(document.status == SubmissionStatus.Pending, "document is already complete");
        if (amount == 0) {
            document.status = SubmissionStatus.Rejected;
            docResults[documentIndex] = DocumentResult({reasonHash: reasonHash, amount: 0});
            emit DocRejected();
            return;
        }
        bytes32 studentId = document.studentId;
        address student = students[studentId];
        mileageToken.mint(student, amount);
        document.status = SubmissionStatus.Approved;
        docResults[documentIndex] = DocumentResult({reasonHash: reasonHash, amount: amount});

        emit DocApproved(documentIndex, studentId, amount);
    }

    function burnFrom(address account, uint256 amount) external onlyAdmin {
        mileageToken.burnFrom(account, amount);
        // emit
    }

    // TODO: signature check
    function requestAccountChange(
        address targetAccount
    ) external returns (uint256) {
        require(studentByAddr[targetAccount] == "");

        bytes32 studentId = studentByAddr[msg.sender];
        require(studentId != "", "account doesn't exist");
        require(students[studentId] == msg.sender, "address validation check failed");

        uint256 requestIndex = requestsCount;
        accountChangeRequests[requestIndex] =
            AccountChangeRequest({status: SubmissionStatus.Pending, studentId: studentId, targetAccount: targetAccount});
        ++requestsCount;

        emit AccountChangeRequested(requestIndex, studentId, msg.sender, targetAccount);
        return requestIndex;
    }

    function approveAccountChange(uint256 index, bool confirm) external onlyAdmin {
        AccountChangeRequest storage request = accountChangeRequests[index];
        require(request.status == SubmissionStatus.Pending, "request is already complete");
        if (!confirm) {
            request.status = SubmissionStatus.Rejected;
            emit AccountChangeRejected();
            return;
        }
        address account = students[request.studentId];
        address nextAccount = request.targetAccount;
        require(studentByAddr[nextAccount] == "");

        bytes32 studentId = request.studentId;

        mileageToken.transferFrom(account, nextAccount, mileageToken.balanceOf(account));
        students[studentId] = nextAccount;
        studentByAddr[nextAccount] = request.studentId;
        request.status = SubmissionStatus.Approved;
        emit AccountChangeApproved(index, studentId, account, nextAccount);
        emit AccountChanged(studentId, account, nextAccount);
    }

    function changeAccount(bytes32 studentId, address target) external onlyAdmin {
        address account = students[studentId];
        students[studentId] = target;
        studentByAddr[target] = studentId;
        emit AccountChanged(studentId, account, target);
    }
}
