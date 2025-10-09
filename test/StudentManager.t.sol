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

contract StudentManagerHarness is StudentManagerImpl {
    constructor(address token, address tokenImpl) StudentManagerImpl(token, tokenImpl) {}
}

contract StudentManagerTest is Test {
    SwMileageTokenImpl public token;
    StudentManagerHarness public manager;
    SwMileageTokenImpl public tokenImpl;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");
    address admin = makeAddr("admin");

    function setUp() public {
        vm.startPrank(admin);
        token = new SwMileageTokenImpl("", "");
        tokenImpl = new SwMileageTokenImpl("", "");
        manager = new StudentManagerHarness(address(token), address(tokenImpl));
        token.addAdmin(address(manager));
        vm.stopPrank();
    }

    function _assertMappingConsistency() private view {
        // Check alice
        bytes32 aliceId = manager.studentByAddr(alice);
        if (aliceId != bytes32(0)) {
            assertEq(manager.students(aliceId), alice);
        }

        // Check bob
        bytes32 bobId = manager.studentByAddr(bob);
        if (bobId != bytes32(0)) {
            assertEq(manager.students(bobId), bob);
        }

        // Check charlie
        bytes32 charlieId = manager.studentByAddr(charlie);
        if (charlieId != bytes32(0)) {
            assertEq(manager.students(charlieId), charlie);
        }
    }

    function _assertUniqueMapping() private view {
        bytes32 aliceId = manager.studentByAddr(alice);
        bytes32 bobId = manager.studentByAddr(bob);
        bytes32 charlieId = manager.studentByAddr(charlie);

        if (aliceId != bytes32(0) && bobId != bytes32(0)) {
            assertTrue(aliceId != bobId);
        }
        if (aliceId != bytes32(0) && charlieId != bytes32(0)) {
            assertTrue(aliceId != charlieId);
        }
        if (bobId != bytes32(0) && charlieId != bytes32(0)) {
            assertTrue(bobId != charlieId);
        }
    }

    function _assertZeroConstraints() private view {
        assertEq(manager.students(bytes32(0)), address(0));
        assertEq(manager.studentByAddr(address(0)), bytes32(0));
    }

    function _assertDocumentState(
        uint256 docIndex
    ) private view {
        IStudentManager.DocumentSubmission memory doc = manager.getDocSubmission(docIndex);
        IStudentManager.DocumentResult memory result = manager.getDocResult(docIndex);

        if (result.processedAt > 0) {
            assertTrue(
                doc.status == IStudentManager.SubmissionStatus.Approved
                    || doc.status == IStudentManager.SubmissionStatus.Rejected
            );
        }
    }

    function _assertBalance(address account, uint256 expected) private view {
        if (token.participated(account)) {
            assertEq(token.balanceOf(account), expected);
        }
    }

    // ============ INITIALIZATION TESTS ============

    function test_initialize_Success() public {
        SwMileageTokenImpl newToken = new SwMileageTokenImpl("", "");
        SwMileageTokenImpl newTokenImpl = new SwMileageTokenImpl("", "");
        StudentManagerHarness newManager = new StudentManagerHarness(address(newToken), address(newTokenImpl));

        newManager.initialize(address(newToken), address(newTokenImpl), admin);

        assertTrue(newManager.isAdmin(admin));
        assertEq(newManager.mileageToken(), address(newToken));
    }

    // ============ TOKEN MANAGEMENT TESTS ============

    function test_changeMileageToken_Success() public {
        SwMileageTokenImpl newToken = new SwMileageTokenImpl("", "");

        vm.prank(admin);
        manager.changeMileageToken(address(newToken));

        assertEq(manager.mileageToken(), address(newToken));
    }

    function test_changeMileageToken_PreservesStudentDataResetsToken() public {
        bytes32 aliceId = keccak256("alice");
        bytes32 bobId = keccak256("bob");

        // Setup students and data
        vm.prank(alice);
        manager.registerStudent(aliceId);
        vm.prank(bob);
        manager.registerStudent(bobId);

        vm.prank(admin);
        manager.mint(aliceId, address(0), 100);
        vm.prank(admin);
        manager.mint(bobId, address(0), 200);

        vm.prank(alice);
        uint256 docIndex = manager.submitDocument(keccak256("document1"));
        vm.prank(admin);
        manager.approveDocument(docIndex, 50, keccak256("approved"));

        uint256 initialAliceBalance = token.balanceOf(alice);
        uint256 initialBobBalance = token.balanceOf(bob);

        // Change token
        SwMileageTokenImpl newToken = new SwMileageTokenImpl("New Mileage Token", "NMT");
        newToken.addAdmin(admin);
        vm.prank(admin);
        newToken.addAdmin(address(manager));
        vm.prank(admin);
        manager.changeMileageToken(address(newToken));

        // Verify student data preserved
        _assertMappingConsistency();
        _assertZeroConstraints();
        assertEq(manager.students(aliceId), alice);
        assertEq(manager.students(bobId), bob);
        assertEq(manager.studentByAddr(alice), aliceId);
        assertEq(manager.studentByAddr(bob), bobId);

        // Verify document preserved
        IStudentManager.DocumentSubmission memory doc = manager.getDocSubmission(0);
        assertEq(uint256(doc.status), uint256(IStudentManager.SubmissionStatus.Approved));
        assertEq(doc.studentId, aliceId);
        assertEq(doc.docHash, keccak256("document1"));
        _assertDocumentState(0);

        // Verify token changed and balances reset
        assertEq(manager.mileageToken(), address(newToken));
        assertEq(newToken.balanceOf(alice), 0);
        assertEq(newToken.balanceOf(bob), 0);
        assertEq(token.balanceOf(alice), initialAliceBalance);
        assertEq(token.balanceOf(bob), initialBobBalance);

        // Verify new token works
        vm.prank(admin);
        manager.mint(aliceId, address(0), 300);
        assertEq(newToken.balanceOf(alice), 300);

        vm.prank(bob);
        uint256 newDocIndex = manager.submitDocument(keccak256("document2"));
        vm.prank(admin);
        manager.approveDocument(newDocIndex, 75, keccak256("approved2"));
        assertEq(newToken.balanceOf(bob), 75);

        _assertMappingConsistency();
        _assertUniqueMapping();
    }

    function test_pause_BlocksUserOperationsWhenPaused() public {
        vm.prank(admin);
        manager.pause();

        vm.prank(alice);
        vm.expectRevert("Pausable: paused");
        manager.registerStudent(keccak256("alice"));

        vm.prank(admin);
        manager.unpause();

        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        assertEq(manager.students(keccak256("alice")), alice);
    }

    // ============ ACCOUNT MANAGEMENT TESTS ============

    function test_registerStudent_Success() public {
        bytes32 studentId = keccak256("alice");

        vm.prank(alice);
        manager.registerStudent(studentId);

        assertEq(manager.students(studentId), alice);
        assertEq(manager.studentByAddr(alice), studentId);
    }

    function test_registerStudent_EmptyId() public {
        vm.prank(charlie);
        vm.expectRevert("empty student ID");
        manager.registerStudent(bytes32(0));
    }

    function test_proposeAccountChange_Success() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        vm.prank(alice);
        manager.proposeAccountChange(bob);

        assertTrue(manager.hasPendingAccountChange(keccak256("alice")));
    }

    function test_proposeAccountChange_RevertsOnInvalidTarget() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        vm.prank(bob);
        manager.registerStudent(keccak256("bob"));

        // Invalid target account (zero address)
        vm.prank(alice);
        vm.expectRevert("invalid target account");
        manager.proposeAccountChange(address(0));

        // Target address already registered
        vm.prank(alice);
        vm.expectRevert("target address already registered");
        manager.proposeAccountChange(bob);

        // Unregistered address trying to propose
        vm.prank(charlie);
        vm.expectRevert("unregistered address");
        manager.proposeAccountChange(makeAddr("newAddr"));
    }

    function test_confirmAccountChange_Success() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        vm.prank(alice);
        manager.proposeAccountChange(bob);

        vm.prank(bob);
        manager.confirmAccountChange(keccak256("alice"));

        assertEq(manager.students(keccak256("alice")), bob);
        assertEq(manager.studentByAddr(bob), keccak256("alice"));
        assertFalse(manager.hasPendingAccountChange(keccak256("alice")));
    }

    function test_confirmAccountChange_WithTokens() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        uint256 balance = 1000;
        vm.prank(admin);
        manager.mint(keccak256("alice"), address(0), balance);

        vm.prank(alice);
        manager.proposeAccountChange(bob);

        vm.prank(bob);
        manager.confirmAccountChange(keccak256("alice"));

        assertEq(manager.students(keccak256("alice")), bob);
        _assertBalance(bob, balance);
        _assertBalance(alice, 0);
    }

    function test_confirmAccountChange_RevertsOnInvalidConfirmation() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        // No pending account change
        vm.prank(bob);
        vm.expectRevert("no pending account change");
        manager.confirmAccountChange(keccak256("alice"));

        vm.prank(alice);
        manager.proposeAccountChange(bob);

        // Wrong confirmation account
        vm.prank(charlie);
        vm.expectRevert("confirmation must be from target account");
        manager.confirmAccountChange(keccak256("alice"));

        // Clear the pending change first
        vm.prank(bob);
        manager.confirmAccountChange(keccak256("alice"));

        // Register new student and try conflicting proposal
        vm.prank(charlie);
        manager.registerStudent(keccak256("charlie"));

        // bob tries to propose to charlie's address
        vm.prank(bob);
        vm.expectRevert("target address already registered");
        manager.proposeAccountChange(charlie);
    }

    function test_changeStudentId_Success() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice_old"));

        vm.prank(alice);
        manager.changeStudentId(keccak256("alice_new"));

        assertEq(manager.students(keccak256("alice_old")), address(0));
        assertEq(manager.students(keccak256("alice_new")), alice);
        assertEq(manager.studentByAddr(alice), keccak256("alice_new"));
    }

    function test_changeStudentId_PreservesTokens() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice_old"));

        vm.prank(admin);
        manager.mint(keccak256("alice_old"), address(0), 500);

        vm.prank(alice);
        manager.changeStudentId(keccak256("alice_new"));

        assertEq(manager.students(keccak256("alice_old")), address(0));
        assertEq(manager.students(keccak256("alice_new")), alice);
        assertEq(manager.studentByAddr(alice), keccak256("alice_new"));
        _assertBalance(alice, 500);

        // Verify pending account change
        assertFalse(manager.hasPendingAccountChange(keccak256("alice")));
        assertFalse(manager.hasPendingAccountChange(keccak256("alice_new")));

        _assertMappingConsistency();
        _assertUniqueMapping();
    }

    function test_changeStudentId_InvalidInput() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        // Empty new student ID
        vm.prank(alice);
        vm.expectRevert("empty new student ID");
        manager.changeStudentId(bytes32(0));

        // Same student ID
        vm.prank(alice);
        vm.expectRevert("student IDs must be different");
        manager.changeStudentId(keccak256("alice"));

        // Existing student ID
        vm.prank(bob);
        manager.registerStudent(keccak256("bob"));

        vm.prank(alice);
        vm.expectRevert("new student ID already exists");
        manager.changeStudentId(keccak256("bob"));

        // Unregistered address
        vm.prank(charlie);
        vm.expectRevert("unregistered address");
        manager.changeStudentId(keccak256("charlie"));
    }

    // ============ DOCUMENT MANAGEMENT TESTS ============

    function test_submitDocument_Success() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        bytes32 docHash = keccak256("document");
        vm.prank(alice);
        uint256 docIndex = manager.submitDocument(docHash);

        IStudentManager.DocumentSubmission memory doc = manager.getDocSubmission(docIndex);
        assertEq(doc.docHash, docHash);
        assertEq(doc.studentId, keccak256("alice"));
        assertEq(uint256(doc.status), uint256(IStudentManager.SubmissionStatus.Pending));
    }

    function test_approveDocument_WithPoints() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        vm.prank(alice);
        uint256 docIndex = manager.submitDocument(keccak256("document"));

        // Test approval with points
        bytes32 reasonHash = keccak256("approved");
        uint256 points = 100;

        vm.prank(admin);
        manager.approveDocument(docIndex, points, reasonHash);

        IStudentManager.DocumentSubmission memory doc = manager.getDocSubmission(docIndex);
        IStudentManager.DocumentResult memory result = manager.getDocResult(docIndex);

        assertEq(uint256(doc.status), uint256(IStudentManager.SubmissionStatus.Approved));
        assertEq(result.amount, points);
        assertEq(result.reasonHash, reasonHash);
        assertTrue(result.processedAt > 0);
        _assertBalance(alice, points);
    }

    function test_approveDocument_Success() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        vm.prank(alice);
        uint256 docIndex = manager.submitDocument(keccak256("document"));

        bytes32 reasonHash = keccak256("approved");
        uint256 points = 100;

        vm.prank(admin);
        manager.approveDocument(docIndex, points, reasonHash);

        IStudentManager.DocumentSubmission memory doc = manager.getDocSubmission(docIndex);
        IStudentManager.DocumentResult memory result = manager.getDocResult(docIndex);

        assertEq(uint256(doc.status), uint256(IStudentManager.SubmissionStatus.Approved));
        assertEq(result.amount, points);
        assertEq(result.reasonHash, reasonHash);
        assertTrue(result.processedAt > 0);

        _assertDocumentState(docIndex);
    }

    function test_approveDocument_RejectsDocumentWithZeroAmount() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        vm.prank(alice);
        uint256 docIndex = manager.submitDocument(keccak256("document"));

        bytes32 reasonHash = keccak256("rejected");

        vm.prank(admin);
        manager.approveDocument(docIndex, 0, reasonHash);

        IStudentManager.DocumentSubmission memory doc = manager.getDocSubmission(docIndex);
        IStudentManager.DocumentResult memory result = manager.getDocResult(docIndex);

        assertEq(uint256(doc.status), uint256(IStudentManager.SubmissionStatus.Rejected));
        assertEq(result.amount, 0);
        assertEq(result.reasonHash, reasonHash);
        assertTrue(result.processedAt > 0);

        _assertDocumentState(docIndex);
    }

    function test_approveDocument_InvalidDoc() public {
        bytes32 reasonHash = keccak256("reason");

        // Document index out of range
        vm.prank(admin);
        vm.expectRevert("document index out of range");
        manager.approveDocument(0, 100, reasonHash);

        // Document not pending (already processed)
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        vm.prank(alice);
        uint256 docIndex = manager.submitDocument(keccak256("doc"));

        vm.prank(admin);
        manager.approveDocument(docIndex, 100, reasonHash);

        vm.prank(admin);
        vm.expectRevert("document not pending");
        manager.approveDocument(docIndex, 200, reasonHash);
    }

    // ============ ADMIN UTILITY TESTS ============

    function test_mint_burnFrom_transferFromToken_Admin() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        vm.prank(bob);
        manager.registerStudent(keccak256("bob"));

        uint256 mintAmount = 1000;
        vm.prank(admin);
        manager.mint(keccak256("alice"), address(0), mintAmount);
        _assertBalance(alice, mintAmount);

        uint256 burnAmount = 300;
        vm.prank(admin);
        manager.burnFrom(keccak256("alice"), address(0), burnAmount);
        _assertBalance(alice, mintAmount - burnAmount);

        uint256 transferAmount = 200;
        vm.prank(admin);
        manager.transferFromToken(keccak256("alice"), keccak256("bob"), transferAmount);
        _assertBalance(alice, mintAmount - burnAmount - transferAmount);
        _assertBalance(bob, transferAmount);
    }

    function test_changeAccount_Success() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        // Add pending account change to test deletion
        vm.prank(alice);
        manager.proposeAccountChange(bob);
        assertTrue(manager.hasPendingAccountChange(keccak256("alice")));

        vm.prank(admin);
        manager.changeAccount(keccak256("alice"), bob);

        assertEq(manager.students(keccak256("alice")), bob);
        assertEq(manager.studentByAddr(bob), keccak256("alice"));

        // Verify pending account change was cleared
        assertFalse(manager.hasPendingAccountChange(keccak256("alice")));
    }

    function test_changeAccount_Override() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        uint256 balance = 500;
        vm.prank(admin);
        manager.mint(keccak256("alice"), address(0), balance);

        vm.prank(admin);
        manager.changeAccount(keccak256("alice"), bob);

        assertEq(manager.students(keccak256("alice")), bob);
        _assertBalance(bob, balance);
        _assertBalance(alice, 0);
    }

    function test_migrateStudentId_AdminCanMigrateStudentId() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice_old"));

        vm.prank(admin);
        manager.mint(keccak256("alice_old"), address(0), 100);

        vm.prank(alice);
        manager.proposeAccountChange(bob);
        assertFalse(manager.hasPendingAccountChange(keccak256("alice")));

        vm.prank(admin);
        manager.migrateStudentId(keccak256("alice_old"), keccak256("alice_new"));

        assertEq(manager.students(keccak256("alice_old")), address(0));
        assertEq(manager.students(keccak256("alice_new")), alice);
        assertEq(manager.studentByAddr(alice), keccak256("alice_new"));
        _assertBalance(alice, 100);

        // Verify pending account change was cleared
        assertFalse(manager.hasPendingAccountChange(keccak256("alice")));
        assertFalse(manager.hasPendingAccountChange(keccak256("alice_migrated")));
    }

    function test_updateStudentRecord_Success() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        // Update with clear = true
        vm.prank(admin);
        manager.updateStudentRecord(keccak256("alice"), bob, true);

        assertEq(manager.students(keccak256("alice")), bob);
        assertEq(manager.studentByAddr(bob), keccak256("alice"));
        assertEq(manager.studentByAddr(alice), bytes32(0));
    }

    function test_updateStudentRecord_NoClear() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        // Update with clear = false
        vm.prank(admin);
        manager.updateStudentRecord(keccak256("alice"), bob, false);

        assertEq(manager.students(keccak256("alice")), bob);
        assertEq(manager.studentByAddr(bob), keccak256("alice"));
        assertEq(manager.studentByAddr(alice), keccak256("alice"));
    }

    function test_updateStudentRecord_ClearsPending() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        vm.prank(alice);
        manager.proposeAccountChange(charlie);

        assertTrue(manager.hasPendingAccountChange(keccak256("alice")));

        vm.prank(admin);
        manager.updateStudentRecord(keccak256("alice"), bob, true);

        assertFalse(manager.hasPendingAccountChange(keccak256("alice")));
    }

    // ============ ADMIN FUNCTIONALITY TESTS ============

    function test_admin_Permissions() public view {
        assertTrue(manager.isAdmin(admin));
        assertTrue(token.isAdmin(admin));
        assertFalse(manager.isAdmin(alice));
    }

    // ============ ADDRESS REUSE PREVENTION TESTS ============

    function test_changeAccount_PreventsReuse() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        // Admin changes account
        vm.prank(admin);
        manager.changeAccount(keccak256("alice"), bob);

        // Design: Old address still maps to studentId (prevents reuse)
        bytes32 oldStudentId = manager.studentByAddr(alice);
        assertEq(oldStudentId, keccak256("alice"));

        // New address also maps to same studentId
        bytes32 newStudentId = manager.studentByAddr(bob);
        assertEq(newStudentId, keccak256("alice"));

        // StudentId points to current active address
        address studentAddr = manager.students(keccak256("alice"));
        assertEq(studentAddr, bob);

        // Old address cannot register new student
        vm.prank(alice);
        vm.expectRevert("address already registered");
        manager.registerStudent(keccak256("charlie"));
    }

    function test_tokenOperations_LegacyHandling() public {
        vm.prank(alice);
        manager.registerStudent(keccak256("alice"));

        vm.prank(admin);
        manager.mint(keccak256("alice"), address(0), 100);

        // Admin changes account
        vm.prank(admin);
        manager.changeAccount(keccak256("alice"), bob);

        // Tokens transferred to new address
        _assertBalance(bob, 100);
        _assertBalance(alice, 0);

        // Only active address works
        vm.prank(admin);
        vm.expectRevert("unauthorized student ID");
        manager.mint(bytes32(0), alice, 50);

        vm.prank(admin);
        vm.expectRevert("unauthorized student ID");
        manager.burnFrom(bytes32(0), alice, 25);

        // New address operations work
        vm.prank(admin);
        manager.mint(bytes32(0), bob, 50);
        _assertBalance(bob, 150);

        vm.prank(admin);
        manager.burnFrom(bytes32(0), bob, 25);
        _assertBalance(bob, 125);
    }
}
