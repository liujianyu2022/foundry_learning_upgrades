// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Store.sol";

contract LogicV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    address public store;

    constructor(){
        _disableInitializers();
    }

    // initialize() 函数用于设置所有权和 UUPS 升级机制
    // 使用 initializer 修饰符，这意味着它只能被调用一次。这是可升级合约的关键部分，因为合约的状态需要在代理合约中正确设置。
    function initiate(address _owner, address _store) public initializer {
        __Ownable_init(_owner);
        __UUPSUpgradeable_init();
        store = _store;
    }

    // UUPS模式特有的 _upgradeTo 函数，由逻辑合约本身负责升级，该函数由 UUPSUpgradeable 合约提供，它负责完成升级的底层逻辑
    // 在 UUPSUpgradeable合约 中 定义了 function _authorizeUpgrade(address newImplementation) internal virtual 该函数在 UUPSUpgradeable合约中 被调用了
    // 因此开发者只需要在逻辑合约中实现 _authorizeUpgrade 函数，用来控制谁可以执行升级操作
    // 注意：下面把形参名注释掉了，这是因为该形参在函数中没有使用，编译器有提示。但是该函数必须要有该形参，不能删除
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function sub(int256 _a, int256 _b) public returns(int256) {
        int256 result = _a - _b;
        Store(store).setResult(result);
        return result;
    }
}