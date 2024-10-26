// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Store.sol";

contract LogicV1 is Initializable, OwnableUpgradeable ,UUPSUpgradeable {
    address public store;

    // 构造函数的主要作用是禁止合约在部署后被初始化。
    // 因为在 UUPS 可升级合约模式中，初始化函数（initialize()）是用于设置合约状态的，而构造函数通常只在合约第一次部署时调用。
    // 调用 _disableInitializers() 函数可以确保在合约部署后，无法再调用任何初始化函数，从而避免意外的重复初始化或状态重置
    constructor() {
        _disableInitializers();
    }

    // initialize() 函数用于设置所有权和 UUPS 升级机制
    // 使用 initializer 修饰符，这意味着它只能被调用一次。这是可升级合约的关键部分，因为合约的状态需要在代理合约中正确设置。
    function initiate(address _owner, address _store) public initializer {
        __Ownable_init(_owner);     // Ownable 合约的初始化函数，负责将合约的所有权设置为调用该函数的地址（通常是合约的部署者）
        __UUPSUpgradeable_init();   // UUPSUpgradeable 合约的初始化函数，负责设置合约的可升级性基础设施
        store = _store;
    }

    // UUPS模式特有的 _upgradeTo 函数，由逻辑合约本身负责升级，该函数由 UUPSUpgradeable 合约提供，它负责完成升级的底层逻辑
    // 在 UUPSUpgradeable合约 中 定义了 function _authorizeUpgrade(address newImplementation) internal virtual 该函数在 UUPSUpgradeable合约中 被调用了
    // 因此开发者只需要在逻辑合约中实现 _authorizeUpgrade 函数，用来控制谁可以执行升级操作
    // 注意：下面把形参名注释掉了，这是因为该形参在函数中没有使用，编译器有提示。但是该函数必须要有该形参，不能删除
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function sum(int256 _a, int256 _b) public returns(int256) {
        int256 result = _a + _b;
        Store(store).setResult(result);
        return result;
    }
}



