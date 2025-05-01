// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {KIP7} from "kaia-contracts/contracts/KIP/token/KIP7/KIP7.sol";
import {IKIP7} from "kaia-contracts/contracts/KIP/token/KIP7/IKIP7.sol";
import {KIP7Burnable} from "kaia-contracts/contracts/KIP/token/KIP7/extensions/KIP7Burnable.sol";
import {Pausable} from "kaia-contracts/contracts/security/Pausable.sol";
import {Admin} from "./Admin.sol";
import {Context} from "kaia-contracts/contracts/utils/Context.sol";

import {SortedList} from "./SortedList.sol";
import {ISwMileageToken} from "./ISwMileageToken.sol";

interface IStudentManager {
    struct DocumentSubmission {
        bytes32 studentId;
        bytes32 docHash;
        DocStatus status;
    }

    struct DocumentResult {
        bytes32 reasonHash;
        uint256 amount;
    }

    enum DocStatus {
        Pending,
        Approved,
        Rejected
    }

    event DocSubmitted(uint256 index, bytes32 studentId, bytes32 docHash);
    event DocApproved(uint256 index, bytes32 studentID, uint256 amount);
    event DocRejected();
    event AccChangeSubmitted();
    event AccChangeApprove();
}
