// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IKIP7} from "kaia-contracts/contracts/KIP/token/KIP7/IKIP7.sol";
import {SwMileageTokenImpl} from "../src/SwMileageToken.impl.sol";
import {StudentManagerImpl} from "../src/StudentManager.impl.sol";
import {IStudentManager} from "../src/IStudentManager.sol";

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
        bytes32 studentId = keccak256(abi.encodePacked("STUDENT1", "123456789")); // safe?
        vm.prank(alice);
        manager.registerStudent(studentId);
        console.logBytes32(studentId);
        assertEq(manager.students(studentId), alice);
        assertEq(manager.studentByAddr(alice), studentId);
    }

    function test_registerStudent_existsAccount() public {
        bytes32 studentId = keccak256(abi.encodePacked("STUDENT1", "123456789")); // safe?
        bytes32 studentId2 = keccak256(abi.encodePacked("STUDENT2", "123456789")); // safe?
        vm.prank(alice);
        manager.registerStudent(studentId);

        assertEq(manager.students(studentId), alice);
        assertEq(manager.studentByAddr(alice), studentId);

        vm.prank(alice);
        vm.expectRevert();
        manager.registerStudent(studentId2);
    }

    function test_registerStudent_existsId() public {
        bytes32 studentId = keccak256(abi.encodePacked("STUDENT1", "123456789")); // safe?
        vm.prank(alice);
        manager.registerStudent(studentId);

        assertEq(manager.students(studentId), alice);
        assertEq(manager.studentByAddr(alice), studentId);

        vm.prank(bob);
        vm.expectRevert();
        manager.registerStudent(studentId);
    }

    function test_submitDocument_notFound() public {
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        vm.expectRevert("account doesn't exist");
        vm.prank(bob);
        manager.submitDocument(docHash);
    }

    function test_submitDocument_vaildationCheck() public {
        bytes32 studentId = keccak256(abi.encodePacked("STUDENT1", "123456789")); // safe?
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        _registerStudent(studentId, bob);

        vm.prank(alice);
        manager.changeAccount(studentId, charlie);

        vm.prank(bob);
        vm.expectRevert("address validation check failed");
        manager.submitDocument(docHash);
    }

    function test_submitDocument_submit() public {
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        bytes32 docHash2 = keccak256("THIS IS SECOND TEST DOCUMENT");
        bytes32 studentId = keccak256(abi.encodePacked("123456789", "123456789")); // safe?
        bytes32 studentId2 = keccak256(abi.encodePacked("987654321", "123456789")); // safe?
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
        bytes32 studentId = keccak256(abi.encodePacked("123456789", "123456789")); // safe?

        _registerStudent(studentId, alice);

        vm.startPrank(alice);

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

        vm.expectRevert();
        manager.approveDocument(index, 200, reasonHash);

        vm.stopPrank();
    }

    function test_approveDocument_reject() public {
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        bytes32 reasonHash = keccak256("THIS IS TEST REASON");
        bytes32 studentId = keccak256(abi.encodePacked("123456789", "123456789")); // safe?

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

    function test_requestAccountChange() public {
        bytes32 studentId = keccak256(abi.encodePacked("123456789", "123456789")); // safe?
        _registerStudent(studentId, bob);

        vm.expectEmit(address(manager));
        emit IStudentManager.AccountChangeRequested(0, studentId, bob, charlie);

        vm.prank(bob);
        uint256 index = manager.requestAccountChange(charlie);

        assertEq(index, 0);

        IStudentManager.AccountChangeRequest memory request = manager.getAccountChangeRequest(index);
        // request.getAccountChangeRequest(1)
        assert(request.status == IStudentManager.SubmissionStatus.Pending);
        assertEq(request.studentId, studentId);
        assertEq(request.targetAccount, charlie);
    }

    function test_changeAccount() public {}
    function test_approveChangeAccount() public {}
}
