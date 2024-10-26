// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

contract LogicV1 {
    function sum(int256 _a, int256 _b) public pure returns(int256) {
        int256 result = _a + _b;
        return result;
    }
}
