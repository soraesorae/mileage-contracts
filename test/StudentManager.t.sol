// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IKIP7} from "kaia-contracts/contracts/KIP/token/KIP7/IKIP7.sol";
import {SwMileageTokenImpl} from "../src/SwMileageToken.impl.sol";
import {StudentManagerImpl} from "../src/StudentManager.impl.sol";
import {IStudentManager} from "../src/IStudentManager.sol";
import {ISwMileageToken} from "../src/ISwMileageToken.sol";

interface IStudentManagerFactory {
    event MileageTokenCreated(address indexed tokenAddress);
}

contract MockStudentManager is StudentManagerImpl {
    constructor(address token, address tokenImpl) StudentManagerImpl(token, tokenImpl) {}

    function changeDocStatus(uint256 index, IStudentManager.SubmissionStatus status) external {
        docSubmissions[index].status = status;
    }
}

contract StudentManagerTest is Test {
    SwMileageTokenImpl public token;
    MockStudentManager public manager;
    SwMileageTokenImpl public tokenImpl;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");

    function setUp() public {
        vm.startPrank(alice);
        token = new SwMileageTokenImpl("", "");
        tokenImpl = new SwMileageTokenImpl("", "");
        manager = new MockStudentManager(address(token), address(tokenImpl));

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

        ISwMileageToken.Student[] memory students = token.getRankingRange(1, 100);
        assertEq(students.length, 1);
        assertEq(students[0].account, bob);
        assertEq(students[0].balance, 50);

        assertEq(token.balanceOf(bob), 50);

        vm.expectEmit(address(manager));
        emit IStudentManager.MileageBurned(studentId, bob, alice, 50);

        vm.prank(alice);
        manager.burnFrom(bytes32(0), bob, 50);

        assertEq(token.balanceOf(bob), 0);

        students = token.getRankingRange(1, 100);
        assertEq(students.length, 0);
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
        bytes32 studentId3 = keccak256(abi.encode("studentId3", "123456789"));

        _registerStudent(studentId3, dummy1);

        vm.prank(dummy1);
        manager.proposeAccountChange(dummy2);

        vm.prank(dummy2);
        manager.confirmAccountChange(studentId3);

        vm.prank(dummy2);
        vm.expectRevert("target address already registered");
        manager.proposeAccountChange(dummy1);
    }

    function test_mint() public {
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        _registerStudent(studentId, bob);

        vm.expectEmit(address(manager));
        emit IStudentManager.MileageMinted(studentId, bob, alice, 100);

        vm.prank(alice);
        manager.mint(studentId, address(0), 100);

        vm.expectEmit(address(manager));
        emit IStudentManager.MileageMinted(studentId, bob, alice, 150);

        vm.prank(alice);
        manager.mint(bytes32(0), bob, 150);
    }

    function test_mint_legacyAccount() public {
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        address newAccount = makeAddr("newAccount");

        _registerStudent(studentId, bob);

        vm.prank(alice);
        manager.changeAccount(studentId, newAccount);

        vm.prank(alice);
        vm.expectRevert("unauthorized student ID");
        manager.mint(bytes32(0), bob, 100);
    }

    function test_burnFrom_legacyAddress() public {
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        address newAccount = makeAddr("newAccount");

        _registerStudent(studentId, bob);

        vm.prank(alice);
        manager.mint(studentId, address(0), 100);

        vm.prank(alice);
        manager.changeAccount(studentId, newAccount);

        vm.prank(alice);
        vm.expectRevert("unauthorized student ID");
        manager.burnFrom(bytes32(0), bob, 50);
    }

    function test_mint_burn_active() public {
        bytes32 studentId = keccak256(abi.encode("studentId", "123456789"));
        address newAccount = makeAddr("newAccount");

        _registerStudent(studentId, bob);

        vm.prank(alice);
        manager.changeAccount(studentId, newAccount);

        vm.prank(alice);
        manager.mint(bytes32(0), newAccount, 100);

        vm.prank(alice);
        manager.burnFrom(bytes32(0), newAccount, 50);
    }

    function test_changeAccount_adminOverride() public {
        bytes32 studentId1 = keccak256(abi.encode("student1", "111"));
        bytes32 studentId2 = keccak256(abi.encode("student2", "222"));
        address student1 = makeAddr("student1");
        address student2 = makeAddr("student2");
        address newAddr1 = makeAddr("newAddr1");
        address newAddr2 = makeAddr("newAddr2");

        _registerStudent(studentId1, student1);
        _registerStudent(studentId2, student2);

        vm.prank(student1);
        manager.proposeAccountChange(newAddr1);

        // Admin changes before confirmation
        vm.prank(alice);
        manager.changeAccount(studentId1, newAddr2);

        // Original proposal should be cleared
        assertEq(manager.getPendingAccountChangeTarget(studentId1), address(0));

        // Can't confirm old proposal
        vm.prank(newAddr1);
        vm.expectRevert("no pending account change");
        manager.confirmAccountChange(studentId1);

        // Original addresses can't be reused
        vm.prank(newAddr2);
        vm.expectRevert("target address already registered");
        manager.proposeAccountChange(student1);
    }

    function test_circularAccountChange() public {
        bytes32 studentId1 = keccak256(abi.encode("student1", "111"));
        bytes32 studentId2 = keccak256(abi.encode("student2", "222"));
        address student1 = makeAddr("student1");
        address student2 = makeAddr("student2");
        address newAddr1 = makeAddr("newAddr1");
        address newAddr2 = makeAddr("newAddr2");

        _registerStudent(studentId1, student1);
        _registerStudent(studentId2, student2);

        vm.prank(student1);
        manager.proposeAccountChange(newAddr1);
        vm.prank(student2);
        manager.proposeAccountChange(newAddr2);

        vm.prank(newAddr1);
        manager.confirmAccountChange(studentId1);
        vm.prank(newAddr2);
        manager.confirmAccountChange(studentId2);

        // Can't use old addresses
        vm.prank(newAddr1);
        vm.expectRevert("target address already registered");
        manager.proposeAccountChange(student2);
    }

    function test_proposeAccountChange_conflicts() public {
        bytes32 studentId1 = keccak256(abi.encode("s1"));
        bytes32 studentId2 = keccak256(abi.encode("s2"));
        address original1 = makeAddr("orig1");
        address original2 = makeAddr("orig2");
        address target1 = makeAddr("tgt1");
        address target2 = makeAddr("tgt2");

        _registerStudent(studentId1, original1);
        _registerStudent(studentId2, original2);

        vm.prank(original1);
        manager.proposeAccountChange(target1);
        vm.prank(original2);
        manager.proposeAccountChange(target2);

        vm.prank(alice);
        manager.changeAccount(studentId1, target2);

        assertEq(manager.getPendingAccountChangeTarget(studentId1), address(0));

        vm.prank(target2);
        vm.expectRevert("target address already registered");
        manager.confirmAccountChange(studentId2);
    }

    function test_changeAccount_recovery() public {
        bytes32 studentId = keccak256(abi.encode("recovery"));
        address original = makeAddr("original");
        address wrong = makeAddr("wrong");
        address recovery = makeAddr("recovery");

        _registerStudent(studentId, original);

        vm.prank(alice);
        manager.changeAccount(studentId, wrong);

        vm.prank(original);
        vm.expectRevert("unauthorized student ID");
        manager.submitDocument(keccak256("doc"));

        vm.prank(alice);
        manager.changeAccount(studentId, recovery);
    }

    function test_deploy_token() public {
        manager.setImplementation(address(tokenImpl));
        string memory name = "Test Token";
        string memory symbol = "TT";
        vm.prank(alice);
        vm.expectEmit(false, false, false, false, address(manager));
        emit IStudentManagerFactory.MileageTokenCreated(address(0));
        address deployed = manager.deployWithAdmin(name, symbol, address(manager));

        assert(deployed != address(0));
        assertEq(SwMileageTokenImpl(deployed).name(), name);
        assertEq(SwMileageTokenImpl(deployed).symbol(), symbol);
        assertEq(SwMileageTokenImpl(deployed).isAdmin(address(manager)), true);

        vm.prank(alice);
        manager.changeMileageToken(deployed);
        _registerStudent(keccak256(abi.encode("studentId", "123456789")), bob);

        vm.prank(bob);
        manager.submitDocument(keccak256("docHash"));

        vm.prank(alice);
        manager.approveDocument(0, 100, keccak256("reasonHash"));
    }
}
