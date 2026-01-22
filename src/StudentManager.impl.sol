// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SwMileageTokenImpl} from "./SwMileageToken.impl.sol";
import {IStudentManager} from "./IStudentManager.sol";
import {SwMileageTokenFactory} from "./SwMileageFactory.sol";
import {Admin} from "./Admin.sol";
import {Initializable} from "kaia-contracts/contracts/proxy/utils/Initializable.sol";
import {Pausable} from "kaia-contracts/contracts/security/Pausable.sol";

contract StudentManagerImpl is IStudentManager, Initializable, SwMileageTokenFactory, Admin, Pausable {
    mapping(bytes32 => address) public students;
    mapping(address => bytes32) public studentByAddr;
    mapping(uint256 => DocumentSubmission) public docSubmissions;
    mapping(uint256 => DocumentResult) public docResults;
    uint256 private documentsCount;

    mapping(bytes32 => AccountChangeProposal) public pendingAccountChanges;
    uint256 private requestsCount;

    SwMileageTokenImpl public _mileageToken;

    constructor(address mileageToken_, address tokenImpl) SwMileageTokenFactory(tokenImpl) {
        _mileageToken = SwMileageTokenImpl(mileageToken_);
    }

    function initialize(address mileageToken_, address tokenImpl, address admin) external initializer {
        _mileageToken = SwMileageTokenImpl(mileageToken_);
        _addAdmin(admin);
        setImplementation(tokenImpl);
    }

    function changeMileageToken(
        address addr
    ) external onlyAdmin {
        _mileageToken = SwMileageTokenImpl(addr);
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    function mileageToken() public view returns (address) {
        return address(_mileageToken);
    }

    ////////////////////////// account

    // check account is EOA
    function registerStudent(
        bytes32 studentId
    ) external whenNotPaused {
        if (studentId == bytes32(0)) revert EmptyStudentId();
        if (students[studentId] != address(0)) revert StudentIdInUse(studentId);
        if (studentByAddr[msg.sender] != bytes32(0)) revert AddressInUse();
        students[studentId] = msg.sender;
        studentByAddr[msg.sender] = studentId;
        emit StudentRegistered(studentId, msg.sender);
    }

    function proposeAccountChange(
        address targetAccount
    ) external whenNotPaused {
        if (targetAccount == address(0) || targetAccount == msg.sender) revert InvalidTargetAccount();
        bytes32 studentId = _validateAccount();
        if (studentByAddr[targetAccount] != bytes32(0)) revert TargetInUse();

        pendingAccountChanges[studentId] =
            AccountChangeProposal({targetAccount: targetAccount, createdAt: block.timestamp});

        emit AccountChangeProposed(studentId, msg.sender, targetAccount);
    }

    function confirmAccountChange(
        bytes32 studentId
    ) external whenNotPaused {
        address currentAccount = students[studentId];
        address targetAccount = pendingAccountChanges[studentId].targetAccount;
        uint256 balance = 0;
        bool isParticipated = false;

        if (targetAccount == address(0)) revert NoPendingChange();
        if (targetAccount != msg.sender) revert UnauthorizedConfirmation();
        if (studentByAddr[targetAccount] != bytes32(0)) revert TargetInUse();

        if (_mileageToken.participated(currentAccount)) {
            isParticipated = true;
            balance = _mileageToken.balanceOf(currentAccount);
        }

        students[studentId] = targetAccount;
        studentByAddr[targetAccount] = studentId;

        delete pendingAccountChanges[studentId];

        if (isParticipated) {
            _mileageToken.transferFrom(currentAccount, targetAccount, balance);
        }

        emit AccountChangeConfirmed(studentId, currentAccount, targetAccount);
        emit AccountChanged(studentId, currentAccount, targetAccount);
    }

    function changeStudentId(
        bytes32 nextId
    ) external whenNotPaused {
        if (nextId == bytes32(0)) revert EmptyStudentId();

        bytes32 currentId = _validateAccount();
        if (currentId == nextId) revert SameStudentId();
        if (students[nextId] != address(0)) revert StudentIdInUse(nextId);

        if (pendingAccountChanges[currentId].targetAccount != address(0)) {
            delete pendingAccountChanges[currentId];
        }

        delete students[currentId];
        students[nextId] = msg.sender;
        studentByAddr[msg.sender] = nextId;

        emit StudentIdChanged(currentId, nextId, msg.sender);
    }

    function getPendingAccountChange(
        bytes32 studentId
    ) external view returns (AccountChangeProposal memory) {
        return pendingAccountChanges[studentId];
    }

    function getPendingAccountChangeTarget(
        bytes32 studentId
    ) public view returns (address) {
        return pendingAccountChanges[studentId].targetAccount;
    }

    function hasPendingAccountChange(
        bytes32 studentId
    ) public view returns (bool) {
        return pendingAccountChanges[studentId].targetAccount != address(0);
    }

    ////////////////////////// document

    function submitDocument(
        bytes32 docHash
    ) external whenNotPaused returns (uint256) {
        bytes32 studentId = _validateAccount();

        uint256 documentIndex = documentsCount++;
        docSubmissions[documentIndex] = DocumentSubmission({
            studentId: studentId,
            docHash: docHash,
            createdAt: block.timestamp,
            status: SubmissionStatus.Pending
        });

        emit DocSubmitted(documentIndex, studentId, docHash);
        return documentIndex;
    }

    function approveDocument(uint256 documentIndex, uint256 amount, bytes32 reasonHash) external onlyAdmin {
        if (documentIndex >= documentsCount) revert InvalidDocIndex(documentIndex, documentsCount);
        DocumentSubmission storage document = docSubmissions[documentIndex];
        if (document.status != SubmissionStatus.Pending) revert NotPendingDocument();

        if (amount == 0) {
            _rejectDocument(documentIndex, reasonHash);
            return;
        }

        bytes32 studentId = document.studentId;
        address student = students[studentId];

        document.status = SubmissionStatus.Approved;
        _mileageToken.mint(student, amount);
        docResults[documentIndex] =
            DocumentResult({reasonHash: reasonHash, amount: amount, processedAt: block.timestamp});

        emit DocApproved(documentIndex, studentId, amount, reasonHash);
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

    ////////////////////////// admin utilities

    function mint(bytes32 studentId, address account, uint256 amount) external onlyAdmin {
        // is valid account, studentId?
        if (account == address(0)) {
            account = students[studentId];
            if (account == address(0)) revert StudentIdNotRegistered();
            _mileageToken.mint(account, amount);
        } else {
            studentId = studentByAddr[account];
            if (studentId == bytes32(0)) revert AddressNotRegistered();
            if (students[studentId] != account) revert StudentIdMismatch(studentId, account);
            _mileageToken.mint(account, amount);
        }
        emit MileageMinted(studentId, account, msg.sender, amount);
    }

    function burnFrom(bytes32 studentId, address account, uint256 amount) external onlyAdmin {
        // is valid account, studentId?
        if (account == address(0)) {
            account = students[studentId];
            if (account == address(0)) revert StudentIdNotRegistered();
            _mileageToken.burnFrom(account, amount);
        } else {
            studentId = studentByAddr[account];
            if (studentId == bytes32(0)) revert AddressNotRegistered();
            if (students[studentId] != account) revert StudentIdMismatch(studentId, account);
            _mileageToken.burnFrom(account, amount);
        }
        emit MileageBurned(studentId, account, msg.sender, amount);
    }

    function changeAccount(bytes32 studentId, address targetAccount) external onlyAdmin {
        if (studentByAddr[targetAccount] != bytes32(0)) revert TargetInUse();
        if (targetAccount == address(0)) revert InvalidTargetAccount();
        address currentAccount = students[studentId];
        uint256 balance = 0;
        bool isParticipated = false;

        if (_mileageToken.participated(currentAccount)) {
            isParticipated = true;
            balance = _mileageToken.balanceOf(currentAccount);
        }

        if (pendingAccountChanges[studentId].targetAccount != address(0)) {
            delete pendingAccountChanges[studentId];
        }

        students[studentId] = targetAccount;
        studentByAddr[targetAccount] = studentId;
        if (isParticipated) {
            _mileageToken.transferFrom(currentAccount, targetAccount, balance);
        }
        emit AccountChanged(studentId, currentAccount, targetAccount);
    }

    function migrateStudentId(bytes32 currentId, bytes32 nextId) external onlyAdmin {
        if (currentId == bytes32(0) || nextId == bytes32(0)) revert EmptyStudentId();
        if (currentId == nextId) revert SameStudentId();

        address account = students[currentId];
        if (account == address(0)) revert StudentIdNotRegistered();
        if (students[nextId] != address(0)) revert StudentIdInUse(nextId);

        if (pendingAccountChanges[currentId].targetAccount != address(0)) {
            delete pendingAccountChanges[currentId];
        }

        delete students[currentId];
        students[nextId] = account;
        studentByAddr[account] = nextId;

        emit StudentIdChanged(currentId, nextId, account);
    }

    // Imediately update student record
    function updateStudentRecord(bytes32 studentId, address targetAccount, bool _clear) external onlyAdmin {
        if (studentId == bytes32(0)) revert EmptyStudentId();

        address currentAccount = students[studentId];

        if (currentAccount != address(0) && _clear) {
            delete studentByAddr[currentAccount];
        }

        if (pendingAccountChanges[studentId].targetAccount != address(0)) {
            delete pendingAccountChanges[studentId];
        }

        students[studentId] = targetAccount;
        studentByAddr[targetAccount] = studentId;

        emit StudentRecordUpdated(studentId, currentAccount, targetAccount);
    }

    function transferFromToken(bytes32 fromStudentId, bytes32 toStudentId, uint256 amount) external onlyAdmin {
        address from = students[fromStudentId];
        address to = students[toStudentId];
        if (from == address(0) || to == address(0)) revert StudentNotRegistered();
        // transfer token directly
        _mileageToken.transferFrom(from, to, amount);
    }

    ////////////////////////// helpers

    function _validateAccount() internal view returns (bytes32) {
        bytes32 studentId = studentByAddr[msg.sender];
        if (studentId == bytes32(0)) revert AddressNotRegistered();
        if (students[studentId] != msg.sender) revert StudentIdMismatch(studentId, msg.sender);
        return studentId;
    }

    function _rejectDocument(uint256 documentIndex, bytes32 reasonHash) internal {
        DocumentSubmission storage document = docSubmissions[documentIndex];
        document.status = SubmissionStatus.Rejected;

        docResults[documentIndex] = DocumentResult({reasonHash: reasonHash, amount: 0, processedAt: block.timestamp});

        emit DocRejected(documentIndex, document.studentId, reasonHash);
    }
}
