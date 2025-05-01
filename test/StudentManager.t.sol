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
        bytes32 studentId = keccak256(abi.encode("STUDENT1", "123456789")); // safe?
        vm.prank(alice);
        manager.registerStudent(studentId);
        console.logBytes32(studentId);
        assertEq(manager.students(studentId), alice);
        assertEq(manager.studentByAddr(alice), studentId);
    }

    function test_registerStudent_existsAccount() public {
        bytes32 studentId = keccak256(abi.encode("STUDENT1", "123456789")); // safe?
        bytes32 studentId2 = keccak256(abi.encode("STUDENT2", "123456789")); // safe?
        vm.prank(alice);
        manager.registerStudent(studentId);

        assertEq(manager.students(studentId), alice);
        assertEq(manager.studentByAddr(alice), studentId);

        vm.prank(alice);
        vm.expectRevert();
        manager.registerStudent(studentId2);
    }

    function test_registerStudent_existsId() public {
        bytes32 studentId = keccak256(abi.encode("STUDENT1", "123456789")); // safe?
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
        bytes32 studentId = keccak256(abi.encode("STUDENT1", "123456789")); // safe?
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
        bytes32 studentId = keccak256(abi.encode("123456789", "123456789")); // safe?
        bytes32 studentId2 = keccak256(abi.encode("987654321", "123456789")); // safe?
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
        bytes32 studentId = keccak256(abi.encode("123456789", "123456789")); // safe?

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
        bytes32 studentId = keccak256(abi.encode("123456789", "123456789")); // safe?

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
        bytes32 studentId = keccak256(abi.encode("123456789", "123456789")); // safe?
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

    function test_approveAccountChange() public {
        bytes32 studentIdA = keccak256(abi.encode("studentA", "123456789")); // safe?
        bytes32 studentIdB = keccak256(abi.encode("studentB", "123456789")); // safe?
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        bytes32 reasonHash = keccak256("THIS IS TEST REASON");

        vm.prank(alice);
        vm.expectRevert("unavailable request");
        manager.approveAccountChange(0, true);

        _registerStudent(studentIdA, alice);
        _registerStudent(studentIdB, bob);

        vm.prank(alice);
        vm.expectRevert("targetAccount already exists");
        manager.requestAccountChange(bob);

        vm.expectEmit(address(manager));
        emit IStudentManager.AccountChangeRequested(0, studentIdA, alice, charlie);
        vm.prank(alice);
        uint256 index = manager.requestAccountChange(charlie);

        vm.expectEmit(address(manager));
        emit IStudentManager.AccountChangeApproved(index, studentIdA, alice, charlie);

        vm.expectEmit(address(manager));
        emit IStudentManager.AccountChanged(studentIdA, alice, charlie);

        vm.prank(alice);
        manager.approveAccountChange(index, true);

        assertEq(manager.students(studentIdA), charlie);

        // bytes32 studentIdC = keccak256(abi.encode("studentC", "123456789")); // safe?
        // bytes32 studentIdD = keccak256(abi.encode("studentD", "123456789")); // safe?
        address dummy1 = makeAddr("ABCD");
        // address dummy2 = makeAddr("ABCDE");

        vm.prank(bob);
        manager.submitDocument(docHash);

        vm.prank(alice);
        manager.approveDocument(0, 200, reasonHash);

        assertEq(token.balanceOf(bob), 200);
        assertEq(token.balanceOf(dummy1), 0);

        vm.prank(bob);
        manager.requestAccountChange(dummy1);

        vm.prank(alice);
        manager.approveAccountChange(1, true);

        assertEq(token.balanceOf(bob), 0);
        assertEq(token.balanceOf(dummy1), 200);

        ISwMileageToken.Student[] memory s = token.getRankingRange(1, 100);
        assertEq(s.length, 1);
        assertEq(s[0].account, dummy1);

        assertEq(manager.students(studentIdB), dummy1);

        // reject scenario
        address dummy2 = makeAddr("dummy2");
        vm.prank(dummy1);
        uint256 index2 = manager.requestAccountChange(dummy2);

        vm.prank(alice);
        manager.approveAccountChange(index2, false);
        assertEq(manager.students(studentIdB), dummy1);

        // zero mileage token balance
        bytes32 studentIdC = keccak256(abi.encode("studentC", "123456789")); // safe?
        address dummy3 = makeAddr("dummy3");
        address dummy4 = makeAddr("dummy4");
        _registerStudent(studentIdC, dummy3);

        vm.prank(dummy3);
        uint256 index3 = manager.requestAccountChange(dummy4);

        vm.prank(alice);
        manager.approveAccountChange(index3, true);

        vm.prank(dummy4);
        uint256 index4 = manager.submitDocument(docHash);

        vm.prank(alice);
        manager.approveDocument(index4, 321, reasonHash);

        assertEq(token.balanceOf(dummy4), 321);

        ISwMileageToken.Student[] memory s1 = token.getRankingRange(1, 100);
        assertEq(s1.length, 2);
        assertEq(s1[0].account, dummy4);
        assertEq(s1[0].balance, 321);
        assertEq(s1[1].account, dummy1);
        assertEq(s1[1].balance, 200);

        // change
        address dummy5 = makeAddr("dummy5");
        vm.prank(dummy4);
        uint256 index5 = manager.requestAccountChange(dummy5);

        vm.prank(alice);
        manager.approveAccountChange(index5, true);

        ISwMileageToken.Student[] memory s2 = token.getRankingRange(1, 100);
        assertEq(s2.length, 2);
        assertEq(s2[0].account, dummy5);
        assertEq(s2[0].balance, 321);
        assertEq(s2[1].account, dummy1);
        assertEq(s2[1].balance, 200);
    }

    function test_approveAccountChange_3steps() public {
        bytes32 studentIdA = keccak256(abi.encode("studentA", "123456789")); // safe?
        // bytes32 studentIdB = keccak256(abi.encode("studentB", "123456789")); // safe?
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        bytes32 reasonHash = keccak256("THIS IS TEST REASON");

        address dummy1 = makeAddr("dummy1");
        address dummy2 = makeAddr("dummy2");
        // address dummy3 = makeAddr("dummy3");

        _registerStudent(studentIdA, bob);

        assertEq(manager.students(studentIdA), bob); // <-- [1]

        vm.prank(bob);
        manager.submitDocument(docHash);

        vm.prank(alice);
        manager.approveDocument(0, 123, reasonHash);

        vm.prank(bob);
        manager.requestAccountChange(dummy1);

        vm.prank(alice);
        manager.approveAccountChange(0, true);

        assertEq(manager.students(studentIdA), dummy1); // <-- [2]
        ISwMileageToken.Student[] memory s1 = token.getRankingRange(1, 100);
        assertEq(s1[0].account, dummy1);
        assertEq(s1[0].balance, 123);

        vm.expectRevert("address validation check failed");
        vm.prank(bob);
        manager.requestAccountChange(dummy2);

        vm.prank(dummy1);
        manager.requestAccountChange(dummy2);

        vm.prank(alice);
        manager.approveAccountChange(1, true);

        assertEq(manager.students(studentIdA), dummy2); // <-- [3]
        ISwMileageToken.Student[] memory s2 = token.getRankingRange(1, 100);
        assertEq(s2[0].account, dummy2);
        assertEq(s2[0].balance, 123);

        vm.expectRevert("targetAccount already exists");
        vm.prank(dummy2);
        manager.requestAccountChange(bob);
    }

    function test_burnFrom() public {
        bytes32 studentIdA = keccak256(abi.encode("studentA", "123456789")); // safe?
        // bytes32 studentIdB = keccak256(abi.encode("studentB", "123456789")); // safe?
        bytes32 docHash = keccak256("THIS IS TEST DOCUMENT");
        bytes32 reasonHash = keccak256("THIS IS TEST REASON");

        _registerStudent(studentIdA, bob);

        assertEq(manager.students(studentIdA), bob); // <-- [1]

        vm.prank(bob);
        manager.submitDocument(docHash);

        vm.prank(alice);
        manager.approveDocument(0, 123, reasonHash);

        ISwMileageToken.Student[] memory s1 = token.getRankingRange(1, 100);
        assertEq(s1[0].account, bob);
        assertEq(s1[0].balance, 123);

        vm.prank(alice);
        manager.burnFrom(studentIdA, address(0), 1);

        ISwMileageToken.Student[] memory s2 = token.getRankingRange(1, 100);
        assertEq(s2[0].account, bob);
        assertEq(s2[0].balance, 122);

        vm.prank(alice);
        manager.burnFrom(studentIdA, address(bob), 1);
        assertEq(s2[0].account, bob);
        assertEq(s2[0].balance, 122);

        vm.expectRevert("KIP7: burn amount exceeds balance");
        vm.prank(alice);
        manager.burnFrom(studentIdA, address(0x1), 1);
    }
}
