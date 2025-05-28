// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IKIP7} from "kaia-contracts/contracts/KIP/token/KIP7/IKIP7.sol";
import {SwMileageTokenImpl} from "../src/SwMileageToken.impl.sol";
import {StudentManagerImpl} from "../src/StudentManager.impl.sol";
import {IStudentManager} from "../src/IStudentManager.sol";
import {ISwMileageToken} from "../src/ISwMileageToken.sol";

contract MockStudentManager is StudentManagerImpl {
    constructor(
        address token
    ) StudentManagerImpl(token) {}

    function changeDocStatus(uint256 index, IStudentManager.SubmissionStatus status) external {
        docSubmissions[index].status = status;
    }
}

contract StudentManagerTest is Test {
    SwMileageTokenImpl public token;
    MockStudentManager public manager;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");

    function setUp() public {
        vm.startPrank(alice);
        token = new SwMileageTokenImpl("", "");
        manager = new MockStudentManager(address(token));

        token.addAdmin(address(manager));

        console.log(address(token));
        vm.stopPrank();
    }

    function _registerStudent(bytes32 studentId, address account) private {
        vm.prank(account);
        manager.registerStudent(studentId);
    }

    function test_admin() public view {
        // Case 1
        assertEq(manager.isAdmin(alice), true);
        assertEq(token.isAdmin(alice), true);
    }

    function test_registerStudent() public {
        // Case 1
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));

        vm.expectEmit(address(manager));
        emit IStudentManager.StudentRegistered(studentId, alice);
        vm.prank(alice);
        manager.registerStudent(studentId);

        console.logBytes32(studentId);
        assertEq(manager.students(studentId), alice);
        assertEq(manager.studentByAddr(alice), studentId);
    }

    function test_registerStudent_fail() public {
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        bytes32 studentId2 = keccak256(abi.encode("studentId2", "123456789"));

        vm.prank(alice);
        manager.registerStudent(studentId);
        console.logBytes32(studentId);
        assertEq(manager.students(studentId), alice);
        assertEq(manager.studentByAddr(alice), studentId);

        vm.expectRevert("address already registered");
        vm.prank(alice);
        manager.registerStudent(studentId2);

        vm.expectRevert("student ID already registered");
        vm.prank(alice);
        manager.registerStudent(studentId);

        vm.expectRevert("student ID already registered");
        vm.prank(bob);
        manager.registerStudent(studentId);
    }

    function test_registerStudent_emptyId() public {
        bytes32 studentId = bytes32(0);
        vm.expectRevert("empty student ID");
        vm.prank(alice);
        manager.registerStudent(studentId);
    }

    function test_registerStudent_alreadyAddrReigstered() public {
        bytes32 studentId1 = keccak256(abi.encode("studentId1", "123456789"));
        vm.prank(bob);
        manager.registerStudent(studentId1);

        assertEq(manager.students(studentId1), bob);
        assertEq(manager.studentByAddr(bob), studentId1);

        vm.prank(bob);
        bytes32 studentId2 = keccak256(abi.encode("studentId2", "123456789"));

        vm.expectRevert("address already registered");
        manager.registerStudent(studentId2);
        vm.stopPrank();
    }

    function test_registerStudent_existsAccount() public {
        // Case 1
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        bytes32 studentId2 = keccak256(abi.encode("studentId2", "123456789"));
        vm.prank(alice);
        manager.registerStudent(studentId);

        assertEq(manager.students(studentId), alice);
        assertEq(manager.studentByAddr(alice), studentId);

        // Case 2
        vm.expectRevert("address already registered");
        vm.prank(alice);
        manager.registerStudent(studentId2);
    }

    function test_registerStudent_existsId() public {
        // Case 1
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        vm.prank(alice);
        manager.registerStudent(studentId);

        assertEq(manager.students(studentId), alice);
        assertEq(manager.studentByAddr(alice), studentId);

        // Case 2
        vm.expectRevert("student ID already registered");
        vm.prank(bob);
        manager.registerStudent(studentId);
    }

    function test_submitDocument_notFound() public {
        // Case 1
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        vm.expectRevert("unregistered address");
        vm.prank(bob);
        manager.submitDocument(docHash);
    }

    function test_submitDocument_vaildationCheck() public {
        // Case 1
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        _registerStudent(studentId, bob);

        vm.prank(alice);
        manager.changeAccount(studentId, charlie);

        vm.expectRevert("unauthorized student ID");
        vm.prank(bob);
        manager.submitDocument(docHash);
    }

    function test_submitDocument_submit() public {
        // Case 1
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        bytes32 docHash2 = keccak256("THIS IS SECOND TEST DOCUMENT");
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        bytes32 studentId2 = keccak256(abi.encode("studentId2", "123456789"));
        _registerStudent(studentId, bob);
        _registerStudent(studentId2, charlie);

        vm.expectEmit(address(manager));
        emit IStudentManager.DocSubmitted(0, studentId, docHash);
        vm.prank(bob);
        uint256 index = manager.submitDocument(docHash);

        assertEq(index, 0);
        IStudentManager.DocumentSubmission memory docs = manager.getDocSubmission(index);
        assert(docs.status == IStudentManager.SubmissionStatus.Pending);
        assertEq(docs.studentId, studentId);
        assertEq(docs.docHash, docHash);

        // Case 2
        vm.expectEmit(address(manager));
        emit IStudentManager.DocSubmitted(1, studentId2, docHash2);
        vm.prank(charlie);
        uint256 index2 = manager.submitDocument(docHash2);

        assertEq(index2, 1);
        IStudentManager.DocumentSubmission memory docs2 = manager.getDocSubmission(index2);
        assert(docs2.status == IStudentManager.SubmissionStatus.Pending);
        assertEq(docs2.studentId, studentId2);
        assertEq(docs2.docHash, docHash2);
    }

    function test_approveDocument_approve() public {
        // Case 1
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        bytes32 reasonHash = keccak256("THIS IS TEST REASON");
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));

        _registerStudent(studentId, alice);

        vm.startPrank(alice);

        vm.expectRevert("document index out of range");
        manager.approveDocument(0, 100, reasonHash);

        // Case 2
        uint256 index = manager.submitDocument(docHash);
        IStudentManager.DocumentSubmission memory docs = manager.getDocSubmission(index);
        assert(docs.status == IStudentManager.SubmissionStatus.Pending);

        vm.expectEmit(address(token));
        emit IKIP7.Transfer(address(0), alice, 100);
        vm.expectEmit(address(manager));
        emit IStudentManager.DocApproved(index, studentId, 100, reasonHash);
        manager.approveDocument(index, 100, reasonHash);

        docs = manager.getDocSubmission(index);
        assert(docs.status == IStudentManager.SubmissionStatus.Approved);
        IStudentManager.DocumentResult memory result = manager.getDocResult(index);
        assertEq(result.amount, 100);
        assertEq(result.reasonHash, reasonHash);
        assertEq(token.balanceOf(alice), 100);

        // Case 3
        console.log("index", index);
        vm.expectRevert("document not pending");
        manager.approveDocument(index, 200, reasonHash);

        vm.stopPrank();
    }

    function test_approveDocument_reject() public {
        // Case 1
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        bytes32 reasonHash = keccak256("THIS IS TEST REASON");
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));

        _registerStudent(studentId, alice);

        vm.startPrank(alice);

        uint256 index = manager.submitDocument(docHash);
        IStudentManager.DocumentSubmission memory docs = manager.getDocSubmission(index);
        assert(docs.status == IStudentManager.SubmissionStatus.Pending);

        // Case 2
        vm.expectEmit(address(manager));
        emit IStudentManager.DocRejected(index, studentId, reasonHash);
        manager.approveDocument(index, 0, reasonHash);

        docs = manager.getDocSubmission(index);
        assert(docs.status == IStudentManager.SubmissionStatus.Rejected);
        assertEq(token.balanceOf(alice), 0);
        IStudentManager.DocumentResult memory result = manager.getDocResult(index);
        assertEq(result.amount, 0);
        assertEq(result.reasonHash, reasonHash);

        vm.stopPrank();
    }

    function test_proposeAccountChange() public {
        // Case 1
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        _registerStudent(studentId, bob);

        vm.expectEmit(address(manager));
        emit IStudentManager.AccountChangeProposed(studentId, bob, charlie);
        vm.prank(bob);
        manager.proposeAccountChange(charlie);

        assertEq(manager.getPendingAccountChangeTarget(studentId), charlie);
    }

    function test_proposeAccountChange_usedAccount() public {
        bytes32 studentId1 = keccak256(abi.encode("studentId1", "123456789"));
        address dummy1 = makeAddr("dummy1");
        address dummy2 = makeAddr("dummy2");

        vm.prank(dummy1);
        manager.registerStudent(studentId1);

        vm.prank(dummy1);
        manager.proposeAccountChange(dummy2);

        vm.prank(dummy2);
        manager.confirmAccountChange(studentId1);

        assertEq(manager.students(studentId1), dummy2);

        vm.expectRevert("target address already registered");
        vm.prank(dummy2);
        manager.proposeAccountChange(dummy1);

        vm.expectRevert("no pending account change");
        vm.prank(dummy1);
        manager.confirmAccountChange(studentId1);
    }

    function test_proposeAccountChange_failures() public {
        // Case 1
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        bytes32 studentId2 = keccak256(abi.encode("studentId2", "123456789"));

        _registerStudent(studentId, bob);
        _registerStudent(studentId2, charlie);

        vm.expectRevert("invalid target account");
        vm.prank(charlie);
        manager.proposeAccountChange(address(0));

        // Case 2
        vm.expectRevert("target address already registered");
        vm.prank(bob);
        manager.proposeAccountChange(charlie);

        // Case 3
        address nonRegisteredAccount = makeAddr("nonRegistered");

        vm.expectRevert("unregistered address");
        vm.prank(nonRegisteredAccount);
        manager.proposeAccountChange(makeAddr("newAccount"));

        // Case 4
        vm.prank(alice);
        manager.changeAccount(studentId, alice);

        vm.expectRevert("unauthorized student ID");
        vm.prank(bob);
        manager.proposeAccountChange(makeAddr("newAccount"));

        // Case 5
        bytes32 studentId3 = keccak256(abi.encode("studentId3", "123456789"));
        address dummy1 = makeAddr("dummy1");
        address dummy2 = makeAddr("dummy2");

        _registerStudent(studentId3, dummy1);

        vm.prank(dummy1);
        manager.proposeAccountChange(dummy2);

        vm.prank(alice);
        manager.changeAccount(studentId3, dummy2);

        vm.expectRevert("no pending account change");
        vm.prank(dummy2);
        manager.confirmAccountChange(studentId3);

        vm.expectRevert("unauthorized student ID");
        vm.prank(dummy1);
        manager.proposeAccountChange(dummy2);
    }

    function test_confirmAccountChange() public {
        // Case 1
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        address newAccount = makeAddr("newAccount");

        _registerStudent(studentId, bob);

        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        bytes32 reasonHash = keccak256("THIS IS TEST REASON");

        vm.prank(bob);
        uint256 docIndex = manager.submitDocument(docHash);

        vm.prank(alice);
        manager.approveDocument(docIndex, 100, reasonHash);

        assertEq(token.balanceOf(bob), 100);

        // Case 2
        vm.prank(bob);
        manager.proposeAccountChange(newAccount);

        // Case 3
        vm.expectEmit(address(manager));
        emit IStudentManager.AccountChangeConfirmed(studentId, bob, newAccount);

        vm.expectEmit(address(manager));
        emit IStudentManager.AccountChanged(studentId, bob, newAccount);

        vm.prank(newAccount);
        manager.confirmAccountChange(studentId);

        // Case 4
        assertEq(manager.students(studentId), newAccount);
        assertEq(manager.studentByAddr(newAccount), studentId);

        assertEq(token.balanceOf(bob), 0);
        assertEq(token.balanceOf(newAccount), 100);

        assertEq(manager.getPendingAccountChangeTarget(studentId), address(0));

        ISwMileageToken.Student[] memory students = token.getRankingRange(1, 100);
        assertEq(students.length, 1);
        assertEq(students[0].account, newAccount);
        assertEq(students[0].balance, 100);
    }

    function test_confirmAccountChange_failures() public {
        // Case 1
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        bytes32 studentId2 = keccak256(abi.encode("studentId2", "123456789"));
        address newAccount = makeAddr("newAccount");
        address wrongAccount = makeAddr("wrongAccount");

        _registerStudent(studentId, bob);

        vm.prank(newAccount);
        vm.expectRevert("no pending account change");
        manager.confirmAccountChange(studentId);

        // Case 2
        vm.prank(bob);
        manager.proposeAccountChange(newAccount);

        vm.prank(wrongAccount);
        vm.expectRevert("confirmation must be from target account");
        manager.confirmAccountChange(studentId);

        // Case 3
        _registerStudent(studentId2, charlie);

        address dummy1 = makeAddr("dummy1");

        vm.prank(charlie);
        manager.proposeAccountChange(dummy1);

        bytes32 studentId3 = keccak256(abi.encode("studentId3", "123456789"));

        _registerStudent(studentId3, dummy1);

        vm.prank(dummy1);
        vm.expectRevert("target address already registered");
        manager.confirmAccountChange(studentId2);
    }

    function test_confirmAccountChange_twoStep() public {
        // Case 1
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        address firstAccount = bob;
        address secondAccount = makeAddr("secondAccount");
        address thirdAccount = makeAddr("thirdAccount");

        _registerStudent(studentId, firstAccount);

        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        bytes32 reasonHash = keccak256("THIS IS TEST REASON");

        vm.prank(firstAccount);
        uint256 docIndex = manager.submitDocument(docHash);

        vm.prank(alice);
        manager.approveDocument(docIndex, 123, reasonHash);

        vm.prank(firstAccount);
        manager.proposeAccountChange(secondAccount);

        vm.prank(secondAccount);
        manager.confirmAccountChange(studentId);

        assertEq(manager.students(studentId), secondAccount);
        assertEq(token.balanceOf(secondAccount), 123);
        assertEq(token.balanceOf(firstAccount), 0);

        // Case 2
        vm.prank(secondAccount);
        manager.proposeAccountChange(thirdAccount);

        vm.prank(thirdAccount);
        manager.confirmAccountChange(studentId);

        assertEq(manager.students(studentId), thirdAccount);
        assertEq(token.balanceOf(thirdAccount), 123);
        assertEq(token.balanceOf(secondAccount), 0);
    }

    function test_confirmAccount_oldAccountsProposal() public {
        // Case 1
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        address firstAccount = bob;
        address secondAccount = makeAddr("secondAccount");
        address anotherAccount = makeAddr("anotherAccount");

        _registerStudent(studentId, firstAccount);

        vm.prank(firstAccount);
        manager.proposeAccountChange(secondAccount);

        vm.prank(secondAccount);
        manager.confirmAccountChange(studentId);

        assertEq(manager.students(studentId), secondAccount);

        // Case 2
        vm.prank(secondAccount);
        manager.proposeAccountChange(anotherAccount);

        vm.prank(alice);
        manager.changeAccount(studentId, anotherAccount);

        vm.prank(secondAccount);
        vm.expectRevert("unauthorized student ID");
        manager.proposeAccountChange(anotherAccount);
    }

    function test_burnFrom() public {
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));

        _registerStudent(studentId, bob);

        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        bytes32 reasonHash = keccak256("THIS IS TEST REASON");

        vm.prank(bob);
        uint256 docIndex = manager.submitDocument(docHash);

        vm.prank(alice);
        manager.approveDocument(docIndex, 100, reasonHash);

        assertEq(token.balanceOf(bob), 100);

        vm.expectEmit(address(manager));
        emit IStudentManager.MileageBurned(studentId, bob, alice, 50);

        vm.prank(alice);
        manager.burnFrom(studentId, address(0), 50);

        assertEq(token.balanceOf(bob), 50);

        vm.expectEmit(address(manager));
        emit IStudentManager.MileageBurned(studentId, bob, alice, 50);

        vm.prank(alice);
        manager.burnFrom(bytes32(0), bob, 50);

        assertEq(token.balanceOf(bob), 0);
    }

    function test_accountChange_zeroBalance() public {
        // Case 1
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        address newAccount = makeAddr("newAccount");

        _registerStudent(studentId, bob);

        // Case 2
        vm.prank(bob);
        manager.proposeAccountChange(newAccount);

        vm.prank(newAccount);
        manager.confirmAccountChange(studentId);

        // Case 3
        assertEq(manager.students(studentId), newAccount);
        assertEq(manager.studentByAddr(newAccount), studentId);

        assertEq(token.balanceOf(bob), 0);
        assertEq(token.balanceOf(newAccount), 0);
    }

    function test_changeAccount() public {
        // Case 1
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        bytes32 studentId2 = keccak256(abi.encode("studentId2", "123456789"));
        address original = alice;
        address target = bob;

        _registerStudent(studentId, original);

        vm.prank(original);
        uint256 docIndex = manager.submitDocument(keccak256("docHash"));

        vm.prank(alice);
        manager.approveDocument(docIndex, 100, keccak256("reasonHash"));

        vm.expectEmit(address(manager));
        emit IStudentManager.AccountChanged(studentId, original, target);

        vm.prank(alice);
        manager.changeAccount(studentId, target);

        assertEq(manager.students(studentId), target);
        assertEq(manager.studentByAddr(target), studentId);
        // assertEq(manager.studentByAddr(original), studentId);

        assertEq(token.balanceOf(original), 0);
        assertEq(token.balanceOf(target), 100);

        // Case 2
        address original2 = charlie;
        address target2 = makeAddr("target2");

        _registerStudent(studentId2, original2);

        vm.prank(alice);
        manager.changeAccount(studentId2, target2);

        assertEq(token.balanceOf(original2), 0);
        assertEq(token.balanceOf(target2), 0);

        // Case 3
        ISwMileageToken.Student[] memory students = token.getRankingRange(1, 100);

        assertEq(students.length, 1);
    }

    function test_updateStudentRecord() public {
        // Case 1
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        address original = bob;
        address dummy0 = makeAddr("dummy0");

        _registerStudent(studentId, original);

        // Award some tokens to the original account
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        bytes32 reasonHash = keccak256("THIS IS TEST REASON");

        vm.prank(original);
        uint256 docIndex = manager.submitDocument(docHash);

        vm.prank(alice);
        manager.approveDocument(docIndex, 100, reasonHash);

        assertEq(token.balanceOf(original), 100);

        vm.expectEmit(address(manager));
        emit IStudentManager.StudentRecordUpdated(studentId, original, dummy0);

        vm.prank(alice);
        manager.updateStudentRecord(studentId, dummy0, false);

        assertEq(manager.students(studentId), dummy0);
        assertEq(manager.studentByAddr(original), studentId);
        assertEq(manager.studentByAddr(dummy0), studentId);

        assertEq(token.balanceOf(original), 100);
        assertEq(token.balanceOf(dummy0), 0);

        // Case 2
        vm.prank(dummy0);
        manager.submitDocument(keccak256("DOCUMENT FROM NEW"));

        vm.expectRevert("unauthorized student ID");
        vm.prank(original);
        manager.submitDocument(keccak256("DOCUMENT FROM ORIGINAL"));

        // Case 3
        assertEq(manager.students(studentId), dummy0);
        vm.prank(alice);
        manager.updateStudentRecord(studentId, dummy0, true); // newAccount -> newAccount

        assertEq(manager.students(studentId), dummy0);
        assertEq(manager.studentByAddr(original), studentId); // not 0
        assertEq(manager.studentByAddr(dummy0), studentId);

        vm.prank(dummy0);
        manager.submitDocument(docHash);

        // Case 4
        address dummy1 = makeAddr("dummy1");
        address dummy2 = makeAddr("dummy2");
        bytes32 studentId1 = keccak256(abi.encode("studentId1", "123456789"));

        vm.prank(dummy1);
        manager.registerStudent(studentId1);

        vm.prank(dummy1);
        uint256 docIndex4 = manager.submitDocument(docHash);

        vm.prank(alice);
        manager.approveDocument(docIndex4, 100, reasonHash);

        assertEq(token.balanceOf(dummy1), 100);

        vm.prank(alice);
        manager.updateStudentRecord(studentId1, dummy2, true);

        // Case 5
        vm.expectRevert("unregistered address");
        vm.prank(dummy1);
        manager.submitDocument(docHash);

        vm.expectRevert("unregistered address");
        vm.prank(dummy1);
        manager.proposeAccountChange(dummy2);

        // Case 6
        address dummy3 = makeAddr("dummy3");
        address dummy4 = makeAddr("dummy4");
        address dummy5 = makeAddr("dummy5");
        bytes32 studentId3 = keccak256(abi.encode("studentId3", "123456789"));

        vm.prank(dummy3);
        manager.registerStudent(studentId3);

        vm.prank(dummy3);
        manager.proposeAccountChange(dummy4);

        vm.prank(alice);
        manager.updateStudentRecord(studentId3, dummy5, false);

        vm.expectRevert("no pending account change");
        vm.prank(dummy4);
        manager.confirmAccountChange(studentId3);
    }

    function test_updateStudentRecord_emptyId() public {
        bytes32 studentId = bytes32(0);

        vm.expectRevert("empty student ID");
        vm.prank(alice);
        manager.updateStudentRecord(studentId, bob, false);

        vm.expectRevert("empty student ID");
        vm.prank(alice);
        manager.updateStudentRecord(studentId, bob, true);
    }

    function test_transferFromToken() public {
        // Case 1
        bytes32 studentId1 = keccak256(abi.encode("studentId1", "123456789"));
        bytes32 studentId2 = keccak256(abi.encode("studentId2", "987654321"));

        _registerStudent(studentId1, bob);
        _registerStudent(studentId2, charlie);

        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        bytes32 reasonHash = keccak256("THIS IS TEST REASON");

        vm.prank(bob);
        uint256 docIndex = manager.submitDocument(docHash);

        vm.prank(alice);
        manager.approveDocument(docIndex, 150, reasonHash);

        assertEq(token.balanceOf(bob), 150);
        assertEq(token.balanceOf(charlie), 0);

        vm.prank(alice);
        manager.transferFromToken(studentId1, studentId2, 50);

        assertEq(token.balanceOf(bob), 100);
        assertEq(token.balanceOf(charlie), 50);

        // Case 2
        address david = makeAddr("david");
        bytes32 studentId4 = keccak256(abi.encode("studentId4", "123"));

        vm.prank(david);
        manager.registerStudent(studentId4);

        vm.prank(david);
        uint256 docIdx = manager.submitDocument(keccak256("PROBLEM_DOC"));

        vm.prank(alice);
        manager.approveDocument(docIdx, 200, keccak256("PROBLEM_REASON"));

        vm.prank(alice);
        manager.updateStudentRecord(studentId4, makeAddr("ghost"), false);

        // Case 3
        address eve = makeAddr("eve");
        bytes32 studentId5 = keccak256(abi.encode("studentId5", "999"));

        vm.prank(eve);
        manager.registerStudent(studentId5);

        vm.expectRevert("KIP7: transfer amount exceeds balance");
        vm.prank(alice);
        manager.transferFromToken(studentId4, studentId5, 200);
    }

    function test_transferFromToken_notRegistered() public {
        bytes32 studentId1 = keccak256(abi.encode("studentId1", "123456789"));
        bytes32 studentId2 = keccak256(abi.encode("studentId2", "987654321"));

        _registerStudent(studentId1, bob);
        _registerStudent(studentId2, charlie);

        vm.expectRevert("students not registered");
        vm.prank(alice);
        manager.transferFromToken(studentId1, bytes32(0), 50);

        vm.expectRevert("students not registered");
        vm.prank(alice);
        manager.transferFromToken(bytes32(0), studentId2, 50);

        vm.expectRevert("students not registered");
        vm.prank(alice);
        manager.transferFromToken(bytes32(0), bytes32(0), 50);
    }

    function test_targetAccountAlreadyExists1() public {
        bytes32 studentId1 = keccak256(abi.encode("studentId1", "123456789"));
        bytes32 studentId2 = keccak256(abi.encode("studentId2", "123456789"));
        address targetAccount = charlie;

        _registerStudent(studentId1, alice);
        _registerStudent(studentId2, bob);

        vm.prank(alice);
        manager.proposeAccountChange(targetAccount);

        vm.prank(bob);
        manager.proposeAccountChange(targetAccount);

        vm.prank(targetAccount);
        manager.confirmAccountChange(studentId1);

        vm.prank(targetAccount);
        vm.expectRevert("target address already registered");
        manager.confirmAccountChange(studentId2);
    }

    function test_targetAccountAlreadyExists2() public {
        bytes32 studentId1 = keccak256(abi.encode("studentId1", "123456789"));
        bytes32 studentId2 = keccak256(abi.encode("studentId2", "123456789"));

        address eve = makeAddr("eve");

        _registerStudent(studentId1, charlie);
        _registerStudent(studentId2, eve);

        vm.prank(charlie);
        vm.expectRevert("target address already registered");
        manager.proposeAccountChange(eve);

        address dummy1 = makeAddr("dummy1");
        address dummy2 = makeAddr("dummy2");
        address dummy3 = makeAddr("account3");
        bytes32 studentId3 = keccak256(abi.encode("studentId3", "123456789"));

        _registerStudent(studentId3, dummy1);

        vm.prank(dummy1);
        manager.proposeAccountChange(dummy2);

        vm.prank(dummy2);
        manager.confirmAccountChange(studentId3);

        vm.prank(dummy2);
        vm.expectRevert("target address already registered");
        manager.proposeAccountChange(dummy1);

        vm.prank(dummy2);
        manager.proposeAccountChange(dummy3);

        vm.prank(dummy3);
        manager.confirmAccountChange(studentId3);

        vm.prank(dummy3);
        vm.expectRevert("target address already registered");
        manager.proposeAccountChange(dummy1);
    }

    function test_mint() public {
        // Case 1: mint by studentId
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        _registerStudent(studentId, bob);

        vm.expectEmit(address(manager));
        emit IStudentManager.MileageMinted(studentId, bob, alice, 100);

        vm.prank(alice);
        manager.mint(studentId, address(0), 100);

        assertEq(token.balanceOf(bob), 100);

        // Case 2: mint by account address
        vm.expectEmit(address(manager));
        emit IStudentManager.MileageMinted(studentId, bob, alice, 150);

        vm.prank(alice);
        manager.mint(bytes32(0), bob, 150);

        assertEq(token.balanceOf(bob), 250);

        // Case 3
        bytes32 studentId2 = keccak256(abi.encode("studentId2", "987654321"));
        _registerStudent(studentId2, charlie);

        vm.expectEmit(address(manager));
        emit IStudentManager.MileageMinted(studentId2, charlie, alice, 200);

        vm.prank(alice);
        manager.mint(studentId2, address(0), 200);

        assertEq(token.balanceOf(charlie), 200);

        assertEq(token.balanceOf(bob), 250);
        assertEq(token.balanceOf(charlie), 200);

        ISwMileageToken.Student[] memory students = token.getRankingRange(1, 100);
        assertEq(students.length, 2);
    }
}
