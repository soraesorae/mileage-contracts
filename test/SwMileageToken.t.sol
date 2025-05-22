// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IKIP7} from "kaia-contracts/contracts/KIP/token/KIP7/IKIP7.sol";
import {ISwMileageToken} from "../src/ISwMileageToken.sol";
import {SwMileageTokenImpl} from "../src/SwMileageToken.impl.sol";
import {SortedList} from "../src/SortedList.sol";
import {ISortedList} from "../src/ISortedList.sol";

contract SwMileageTokenTest is Test {
    SwMileageTokenImpl public mileageToken;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");

    function setUp() public {
        vm.prank(alice);
        mileageToken = new SwMileageTokenImpl("", "");
        mileageToken.initialize("SwMileageToken", "SMT", alice);
    }

    function test_token() public view {
        assertEq("SwMileageToken", mileageToken.name());
        assertEq("SMT", mileageToken.symbol());
    }

    function test_isAdmin() public view {
        assertEq(mileageToken.isAdmin(alice), true);
    }

    function test_mint_Admin() public {
        vm.expectEmit(address(mileageToken));
        emit IKIP7.Transfer(address(0), bob, 10);

        vm.expectEmit(address(mileageToken));
        emit ISortedList.UpdateElement(bob, 0, 10);

        vm.prank(alice);
        mileageToken.mint(bob, 10);

        assertEq(mileageToken.balanceOf(bob), 10);
    }

    function test_mint_NoAdmin() public {
        vm.prank(alice);
        mileageToken.mint(bob, 10);

        vm.expectRevert(bytes("caller is not the admin"));
        vm.prank(charlie);
        mileageToken.burnFrom(bob, 1);
    }

    function test_mint_Twice() public {
        vm.startPrank(alice);

        vm.expectEmit(address(mileageToken));
        emit IKIP7.Transfer(address(0), bob, 10);

        vm.expectEmit(address(mileageToken));
        emit ISortedList.UpdateElement(bob, 0, 10);

        mileageToken.mint(bob, 10);

        assertEq(mileageToken.balanceOf(bob), 10);

        vm.expectEmit(address(mileageToken));
        emit IKIP7.Transfer(address(0), charlie, 20);

        mileageToken.mint(charlie, 20);

        assertEq(mileageToken.balanceOf(charlie), 20);
    }

    function test_burn_Admin() public {
        vm.startPrank(alice);
        mileageToken.mint(bob, 10);
        vm.expectRevert("burn is not allowed");
        mileageToken.burn(5);

        assertEq(mileageToken.balanceOf(bob), 10);
    }

    function test_burn_NotAdmin() public {
        vm.prank(alice);
        mileageToken.mint(bob, 10);

        vm.prank(bob);
        vm.expectRevert("burn is not allowed");
        mileageToken.burn(5);

        assertEq(mileageToken.balanceOf(bob), 10);
    }

    function test_burnFrom_Admin() public {
        vm.startPrank(alice);

        vm.expectEmit(address(mileageToken));
        emit IKIP7.Transfer(address(0), bob, 10);

        mileageToken.mint(bob, 10);
        assertEq(mileageToken.allowance(bob, alice), 0);

        vm.expectEmit(address(mileageToken));
        emit IKIP7.Transfer(bob, address(0), 5);

        mileageToken.burnFrom(bob, 5);
        assertEq(mileageToken.balanceOf(bob), 5);
    }

    function test_burnFrom_NotAdmin() public {
        vm.prank(alice);
        mileageToken.mint(bob, 10);

        vm.expectRevert(bytes("caller is not the admin"));
        vm.prank(charlie);
        mileageToken.burnFrom(charlie, 1);
    }

    function test_burnFrom_Edge() public {
        vm.startPrank(alice);
        mileageToken.mint(bob, 20);
        mileageToken.burnFrom(bob, 10);
        {
            ISwMileageToken.Student[] memory result = mileageToken.getRankingRange(1, 2);
            assertEq(result.length, 1);
            assertEq(result[0].account, bob);
            assertEq(result[0].balance, 10);
        }
        mileageToken.burnFrom(bob, 10);
        {
            ISwMileageToken.Student[] memory result = mileageToken.getRankingRange(1, 2);
            assertEq(result.length, 0);
        }
    }

    function test_burnFrom_0() public {
        vm.expectRevert("not in list");
        vm.startPrank(alice);
        mileageToken.burnFrom(bob, 0);
    }

    function testRemoveAfterBurn() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address user4 = makeAddr("user4");

        vm.startPrank(alice);
        mileageToken.mint(user1, 30);
        mileageToken.mint(user2, 20);
        mileageToken.mint(user3, 10);
        mileageToken.burnFrom(user2, 10);
        {
            ISwMileageToken.Student[] memory s = mileageToken.getRankingRange(1, 100);

            address[3] memory x = [user1, user3, user2];
            uint256[3] memory y = [uint256(30), 10, 10];

            for (uint256 i = 0; i < 3; i++) {
                assertEq(s[i].account, x[i]);
                assertEq(s[i].balance, y[i]);
            }
        }

        mileageToken.burnFrom(user3, 5);
        {
            ISwMileageToken.Student[] memory s = mileageToken.getRankingRange(1, 100);

            address[3] memory x = [user1, user2, user3];
            uint256[3] memory y = [uint256(30), 10, 5];

            for (uint256 i = 0; i < 3; i++) {
                assertEq(s[i].account, x[i]);
                assertEq(s[i].balance, y[i]);
            }
        }

        mileageToken.burnFrom(user2, 10);

        {
            ISwMileageToken.Student[] memory s = mileageToken.getRankingRange(1, 100);

            address[2] memory x = [user1, user3];
            uint256[2] memory y = [uint256(30), 5];

            for (uint256 i = 0; i < 2; i++) {
                assertEq(s[i].account, x[i]);
                assertEq(s[i].balance, y[i]);
            }
        }

        mileageToken.mint(user4, 20);

        {
            ISwMileageToken.Student[] memory s = mileageToken.getRankingRange(1, 100);

            address[3] memory x = [user1, user4, user3];
            uint256[3] memory y = [uint256(30), 20, 5];

            for (uint256 i = 0; i < 3; i++) {
                assertEq(s[i].account, x[i]);
                assertEq(s[i].balance, y[i]);
            }
        }

        mileageToken.mint(user2, 40);

        {
            ISwMileageToken.Student[] memory s = mileageToken.getRankingRange(1, 100);

            address[4] memory x = [user2, user1, user4, user3];
            uint256[4] memory y = [uint256(40), 30, 20, 5];

            for (uint256 i = 0; i < 4; i++) {
                assertEq(s[i].account, x[i]);
                assertEq(s[i].balance, y[i]);
            }
        }

        mileageToken.burnFrom(user2, 10);

        {
            ISwMileageToken.Student[] memory s = mileageToken.getRankingRange(1, 100);

            address[4] memory x = [user1, user2, user4, user3];
            uint256[4] memory y = [uint256(30), 30, 20, 5];

            for (uint256 i = 0; i < 4; i++) {
                assertEq(s[i].account, x[i]);
                assertEq(s[i].balance, y[i]);
            }
        }

        mileageToken.burnFrom(user2, 30);

        {
            ISwMileageToken.Student[] memory s = mileageToken.getRankingRange(1, 100);

            address[3] memory x = [user1, user4, user3];
            uint256[3] memory y = [uint256(30), 20, 5];

            for (uint256 i = 0; i < 3; i++) {
                assertEq(s[i].account, x[i]);
                assertEq(s[i].balance, y[i]);
            }
        }

        mileageToken.mint(user2, 10);

        {
            ISwMileageToken.Student[] memory s = mileageToken.getRankingRange(1, 100);

            address[4] memory x = [user1, user4, user2, user3];
            uint256[4] memory y = [uint256(30), 20, 10, 5];

            for (uint256 i = 0; i < 4; i++) {
                assertEq(s[i].account, x[i]);
                assertEq(s[i].balance, y[i]);
            }
        }
    }

    function test_transferFrom_Admin() public {
        vm.startPrank(alice);
        mileageToken.mint(alice, 100);
        mileageToken.mint(bob, 100);
        vm.stopPrank();

        vm.prank(alice);
        mileageToken.transferFrom(bob, alice, 50);
        assertEq(mileageToken.balanceOf(alice), 150);
    }

    function test_transferFrom() public {
        vm.startPrank(alice);
        mileageToken.mint(alice, 100);
        mileageToken.mint(bob, 100);
        vm.stopPrank();

        ISwMileageToken.Student[] memory s0 = mileageToken.getRankingRange(1, 100);

        assertEq(s0[0].account, alice);
        assertEq(s0[1].account, bob);

        vm.prank(alice);
        mileageToken.transferFrom(alice, bob, 50);
        assertEq(mileageToken.balanceOf(bob), 150);

        ISwMileageToken.Student[] memory s1 = mileageToken.getRankingRange(1, 100);

        assertEq(s1[0].account, bob);
        assertEq(s1[1].account, alice);
    }

    function test_transferFrom_toZero() public {
        vm.startPrank(alice);
        mileageToken.mint(bob, 100);
        mileageToken.mint(charlie, 150);
        mileageToken.transferFrom(charlie, bob, 150);
        vm.stopPrank();
        assertEq(mileageToken.balanceOf(bob), 250);

        ISwMileageToken.Student[] memory s0 = mileageToken.getRankingRange(1, 100);

        assertEq(s0.length, 1);
        assertEq(s0[0].account, bob);
        assertEq(s0[0].balance, 250);
    }

    function testDoubleRemove() public {
        address user1 = makeAddr("user1");
        vm.startPrank(alice);
        mileageToken.mint(user1, 10);

        mileageToken.burnFrom(user1, 10);
        {
            ISwMileageToken.Student[] memory s = mileageToken.getRankingRange(1, 100);
            assertEq(s.length, 0);
        }

        vm.expectRevert("KIP7: burn amount exceeds balance");
        mileageToken.burnFrom(user1, 10);

        mileageToken.mint(user1, 10);
        {
            ISwMileageToken.Student[] memory s = mileageToken.getRankingRange(1, 100);
            assertEq(s.length, 1);
            assertEq(s[0].account, user1);
            assertEq(s[0].balance, 10);
        }
    }

    function testMultipleAdmin() public {}

    function test_getRankingRange() public {
        vm.startPrank(alice);
        mileageToken.mint(alice, 0x1);
        mileageToken.mint(bob, 0x10);
        mileageToken.mint(charlie, 0x1000);

        ISwMileageToken.Student[] memory students1 = mileageToken.getRankingRange(1, 2);

        assertEq(students1[0].account, charlie);
        assertEq(students1[1].account, bob);

        mileageToken.mint(alice, 0x10);

        ISwMileageToken.Student[] memory students2 = mileageToken.getRankingRange(1, 10);

        assertEq(students2[0].account, charlie);
        assertEq(students2[1].account, alice);
        assertEq(students2[2].account, bob);

        mileageToken.burnFrom(charlie, 0x1000);

        ISwMileageToken.Student[] memory students3 = mileageToken.getRankingRange(1, 10);

        assertEq(students3[0].account, alice);
        assertEq(students3[1].account, bob);
    }

    function test_getRankingRangeNoOne() public {
        vm.startPrank(alice);
        ISwMileageToken.Student[] memory s = mileageToken.getRankingRange(1, 10);
        assertEq(s.length, 0);
    }

    function test_getRankingRangeNot() public {
        vm.startPrank(alice);
        ISwMileageToken.Student[] memory s = mileageToken.getRankingRange(10, 10);
        assertEq(s.length, 0);
    }

    function test_addAdmin() public {
        vm.expectRevert("caller is not the admin");
        vm.prank(bob);
        mileageToken.mint(bob, 0x10);

        vm.prank(alice);
        mileageToken.addAdmin(bob);

        vm.prank(bob);
        mileageToken.mint(bob, 0x10);

        assertEq(mileageToken.balanceOf(bob), 0x10);
    }

    function test_removeAdmin() public {
        vm.expectRevert("caller is not the admin");
        vm.prank(bob);
        mileageToken.mint(bob, 0x10);

        vm.prank(alice);
        mileageToken.addAdmin(bob);

        vm.startPrank(bob);
        mileageToken.mint(bob, 0x10);

        assertEq(mileageToken.balanceOf(bob), 0x10);
        vm.stopPrank();

        vm.prank(alice);
        mileageToken.removeAdmin(bob);

        vm.expectRevert("caller is not the admin");
        vm.prank(bob);
        mileageToken.mint(bob, 0x10);
    }

    function test_transfer_NotPermitted() public {
        vm.startPrank(alice);
        mileageToken.mint(alice, 100);
        mileageToken.mint(bob, 100);
        vm.stopPrank();

        vm.prank(bob);
        vm.expectRevert("admin only operation");
        mileageToken.transfer(alice, 50);
    }

    function test_transferFrom_NotPermitted() public {
        vm.startPrank(alice);
        mileageToken.mint(alice, 100);
        mileageToken.mint(bob, 100);
        vm.stopPrank();

        vm.prank(bob);
        vm.expectRevert("caller is not the admin");
        mileageToken.transferFrom(bob, alice, 50);
    }

    function test_approve_NotPermitted() public {
        vm.prank(bob);
        vm.expectRevert("approval is not allowed");
        mileageToken.approve(bob, 50);
    }

    function test_getRankingRange_InvalidParams() public {
        vm.startPrank(alice);

        vm.expectRevert("from is zero");
        mileageToken.getRankingRange(0, 10);

        vm.expectRevert("to < from");
        mileageToken.getRankingRange(10, 5);
        vm.stopPrank();
    }
}
