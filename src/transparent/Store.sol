// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

contract Store {
    int256 private result;

    function getResult() external view returns (int256) {
        return result;
    }

    function setResult(int256 _result) external {
        result = _result;
    }
}