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
        SwMileageTokenImpl token
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
        manager = new MockStudentManager(token);

        token.addAdmin(address(manager));

        console.log(address(token));
        vm.stopPrank();
    }

    function _registerStudent(bytes32 studentId, address account) private {
        vm.prank(account);
        manager.registerStudent(studentId);
    }

    function test_admin() public view {
        assertEq(manager.isAdmin(alice), true);
        assertEq(token.isAdmin(alice), true);
    }

    function test_registerStudent() public {
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        vm.prank(alice);
        manager.registerStudent(studentId);
        console.logBytes32(studentId);
        assertEq(manager.students(studentId), alice);
        assertEq(manager.studentByAddr(alice), studentId);
    }

    function test_registerStudent_existsAccount() public {
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        bytes32 studentId2 = keccak256(abi.encode("studentId2", "123456789"));
        vm.prank(alice);
        manager.registerStudent(studentId);

        assertEq(manager.students(studentId), alice);
        assertEq(manager.studentByAddr(alice), studentId);

        vm.expectRevert();
        vm.prank(alice);
        manager.registerStudent(studentId2);
    }

    function test_registerStudent_existsId() public {
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        vm.prank(alice);
        manager.registerStudent(studentId);

        assertEq(manager.students(studentId), alice);
        assertEq(manager.studentByAddr(alice), studentId);

        vm.expectRevert();
        vm.prank(bob);
        manager.registerStudent(studentId);
    }

    function test_submitDocument_notFound() public {
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        vm.expectRevert("account doesn't exist");
        vm.prank(bob);
        manager.submitDocument(docHash);
    }

    function test_submitDocument_vaildationCheck() public {
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        _registerStudent(studentId, bob);

        vm.prank(alice);
        manager.changeAccount(studentId, charlie);

        vm.expectRevert("address validation check failed");
        vm.prank(bob);
        manager.submitDocument(docHash);
    }

    function test_submitDocument_submit() public {
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
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        bytes32 reasonHash = keccak256("THIS IS TEST REASON");
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));

        _registerStudent(studentId, alice);

        vm.startPrank(alice);

        vm.expectRevert("unavailable document");
        manager.approveDocument(0, 100, reasonHash);

        uint256 index = manager.submitDocument(docHash);
        IStudentManager.DocumentSubmission memory docs = manager.getDocSubmission(index);
        assert(docs.status == IStudentManager.SubmissionStatus.Pending);

        vm.expectEmit(address(token));
        emit IKIP7.Transfer(address(0), alice, 100);
        vm.expectEmit(address(manager));
        emit IStudentManager.DocApproved(index, studentId, 100);
        manager.approveDocument(index, 100, reasonHash);

        docs = manager.getDocSubmission(index);
        assert(docs.status == IStudentManager.SubmissionStatus.Approved);
        IStudentManager.DocumentResult memory result = manager.getDocResult(index);
        assertEq(result.amount, 100);
        assertEq(result.reasonHash, reasonHash);
        assertEq(token.balanceOf(alice), 100);

        vm.expectRevert("unavailable document");
        manager.approveDocument(index, 200, reasonHash);

        vm.stopPrank();
    }

    function test_approveDocument_reject() public {
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        bytes32 reasonHash = keccak256("THIS IS TEST REASON");
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));

        _registerStudent(studentId, alice);

        vm.startPrank(alice);

        uint256 index = manager.submitDocument(docHash);
        IStudentManager.DocumentSubmission memory docs = manager.getDocSubmission(index);
        assert(docs.status == IStudentManager.SubmissionStatus.Pending);

        vm.expectEmit(address(manager));
        emit IStudentManager.DocRejected();
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
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        _registerStudent(studentId, bob);

        vm.expectEmit(address(manager));
        emit IStudentManager.AccountChangeProposed(studentId, charlie);
        vm.prank(bob);
        manager.proposeAccountChange(charlie);

        assertEq(manager.pendingAccountChanges(studentId), charlie);
    }

    function test_proposeAccountChange_failures() public {
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        bytes32 studentId2 = keccak256(abi.encode("studentId2", "123456789"));

        _registerStudent(studentId, bob);
        _registerStudent(studentId2, charlie);

        vm.expectRevert("invalid targetAccount");
        vm.prank(charlie);
        manager.proposeAccountChange(address(0));

        vm.expectRevert("targetAccount already exists");
        vm.prank(bob);
        manager.proposeAccountChange(charlie);

        address nonRegisteredAccount = makeAddr("nonRegistered");

        vm.expectRevert("account doesn't exist");
        vm.prank(nonRegisteredAccount);
        manager.proposeAccountChange(makeAddr("newAccount"));

        vm.prank(alice);
        manager.changeAccount(studentId, alice);

        vm.expectRevert("address validation check failed");
        vm.prank(bob);
        manager.proposeAccountChange(makeAddr("newAccount"));

        bytes32 studentId3 = keccak256(abi.encode("studentId3", "123456789"));
        address dummy1 = makeAddr("dummy1");
        address dummy2 = makeAddr("dummy2");

        _registerStudent(studentId3, dummy1);

        vm.prank(dummy1);
        manager.proposeAccountChange(dummy2);

        vm.prank(alice);
        manager.changeAccount(studentId3, dummy2);

        vm.prank(dummy2);
        vm.expectRevert("targetAccount already exists");
        manager.confirmAccountChange(studentId3);

        vm.prank(dummy1);
        vm.expectRevert("address validation check failed");
        manager.proposeAccountChange(dummy2);
    }

    function test_confirmAccountChange() public {
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

        vm.prank(bob);
        manager.proposeAccountChange(newAccount);

        vm.prank(newAccount);
        vm.expectEmit(address(manager));
        emit IStudentManager.AccountChangeConfirmed(studentId, newAccount);
        vm.expectEmit(address(manager));
        emit IStudentManager.AccountChanged(studentId, bob, newAccount);
        manager.confirmAccountChange(studentId);

        assertEq(manager.students(studentId), newAccount);
        assertEq(manager.studentByAddr(newAccount), studentId);

        assertEq(token.balanceOf(bob), 0);
        assertEq(token.balanceOf(newAccount), 100);

        assertEq(manager.pendingAccountChanges(studentId), address(0));

        ISwMileageToken.Student[] memory students = token.getRankingRange(1, 100);
        assertEq(students.length, 1);
        assertEq(students[0].account, newAccount);
        assertEq(students[0].balance, 100);
    }

    function test_confirmAccountChange_failures() public {
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        bytes32 studentId2 = keccak256(abi.encode("studentId2", "123456789"));
        address newAccount = makeAddr("newAccount");
        address wrongAccount = makeAddr("wrongAccount");

        _registerStudent(studentId, bob);

        vm.prank(newAccount);
        vm.expectRevert("invalid targetAccount");
        manager.confirmAccountChange(studentId);

        vm.prank(bob);
        manager.proposeAccountChange(newAccount);

        vm.prank(wrongAccount);
        vm.expectRevert("unauthorized confirmation");
        manager.confirmAccountChange(studentId);

        _registerStudent(studentId2, charlie);

        address dummy1 = makeAddr("dummy1");

        vm.prank(charlie);
        manager.proposeAccountChange(dummy1);

        bytes32 studentId3 = keccak256(abi.encode("studentId3", "123456789"));

        _registerStudent(studentId3, dummy1);

        vm.prank(dummy1);
        vm.expectRevert("targetAccount already exists");
        manager.confirmAccountChange(studentId2);
    }

    function test_confirmAccountChange_twoStep() public {
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

        vm.prank(secondAccount);
        manager.proposeAccountChange(thirdAccount);

        vm.prank(thirdAccount);
        manager.confirmAccountChange(studentId);

        assertEq(manager.students(studentId), thirdAccount);
        assertEq(token.balanceOf(thirdAccount), 123);
        assertEq(token.balanceOf(secondAccount), 0);
    }

    function test_confirmAccount_oldAccountsProposal() public {
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

        vm.prank(secondAccount);
        manager.proposeAccountChange(anotherAccount);

        vm.prank(alice);
        manager.changeAccount(studentId, anotherAccount);

        vm.prank(secondAccount);
        vm.expectRevert("address validation check failed");
        manager.proposeAccountChange(anotherAccount);
    }

    function test_accountChange_zeroBalance() public {
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        address newAccount = makeAddr("newAccount");

        _registerStudent(studentId, bob);

        vm.prank(bob);
        manager.proposeAccountChange(newAccount);

        vm.prank(newAccount);
        manager.confirmAccountChange(studentId);

        assertEq(manager.students(studentId), newAccount);
        assertEq(manager.studentByAddr(newAccount), studentId);

        assertEq(token.balanceOf(bob), 0);
        assertEq(token.balanceOf(newAccount), 0);
    }

    function test_changeAccount() public {
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
        assertEq(manager.studentByAddr(original), studentId);

        assertEq(token.balanceOf(original), 0);
        assertEq(token.balanceOf(target), 100);

        //////////

        address original2 = charlie;
        address target2 = makeAddr("target2");

        _registerStudent(studentId2, original2);

        vm.prank(alice);
        manager.changeAccount(studentId2, target2);

        assertEq(token.balanceOf(original2), 0);
        assertEq(token.balanceOf(target2), 0);

        ISwMileageToken.Student[] memory students = token.getRankingRange(1, 100);

        assertEq(students.length, 1);
    }
}
