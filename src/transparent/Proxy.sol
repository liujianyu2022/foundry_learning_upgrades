// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

import "./Store.sol";

contract Proxy {
    address public logic;
    address public store;
    address public admini;

    modifier onlyAdmini {
        require(msg.sender == admini, "Only administrator can upgrade !");
        _;
    }

    constructor(address _logic, address _store, address _admini){
        logic = _logic;
        store = _store;
        admini = _admini;
    }

    function upgrade(address _newLogic) onlyAdmini external {
        logic = _newLogic;
    }

    // 使用fallback函数转发所有调用
    // 当调用 proxy 合约中不存在的函数时，fallback函数会被调用，从而触发delegatecall
    fallback() external payable {

        // 检查调用者是否为管理员，防止管理员直接调用逻辑合约的函数
        // 确保管理员无法通过代理合约调用逻辑合约的业务函数。这就是透明性机制的核心，即管理员只能进行合约管理操作，不能影响合约的业务逻辑执行。
        require(msg.sender != admini, "Admin cannot directly call logic functions");

        // 获取参数并调用存储合约的setA和setB
        // msg.data[4:] 是一个切片操作，表示从 msg.data 字节数组的第 4 个字节开始提取数据。
        // 这里的 4 是因为在 Solidity 中，函数调用的前 4 个字节是函数选择器（function selector），用于指明被调用的函数
        // 举例：sum(int, int)，它的选择器是 bytes4(keccak256("sum(int256,int256)"))
        // (int a, int b) = abi.decode(msg.data[4:], (int, int));

        (bool success, bytes memory data) = logic.delegatecall(msg.data);

        require(success, "Delegatecall failed");

        int256 result = abi.decode(data, (int256));
        Store(store).setResult(result);

        // 将返回的数据返回给调用者
        assembly {
            return(add(data, 0x20), mload(data))
        }
    }

    receive() external payable {}
}