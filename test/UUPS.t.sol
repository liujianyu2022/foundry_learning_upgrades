// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../src/UUPS/LogicV1.sol";
import "../src/UUPS/LogicV2.sol";
import "../src/UUPS/Store.sol";

contract UUPSTest is Test {
    LogicV1 public logicV1;
    LogicV2 public logicV2;
    Store public store;
    ERC1967Proxy public proxy;
    address owner = makeAddr("owner");

    function setUp() public {
        store = new Store();
        logicV1 = new LogicV1();
        logicV2 = new LogicV2();

        bytes memory data = abi.encodeWithSignature(
            "initiate(address,address)",                        // note: there can be NO space between each parameter!
            address(owner),                                     // set the owner of the proxy
            address(store)
        );

        // 在 ERC1967Proxy 的构造函数中，第二个参数 data 用于在代理合约部署后立即调用逻辑合约中的一个函数，通常用于初始化逻辑合约的状态。
        // 这里在代理合约部署后立即调用了 logicV1.initiate()，初始化了逻辑合约的状态，避免了忘记初始化的错误发生
        // 如果不传 data 参数，则代理合约会指向 logicV1 合约，但不会自动调用任何初始化函数，需手动调用初始化函数来设置状态。
        proxy = new ERC1967Proxy(address(logicV1), data);

        // 由于上面已经调用了 initialize的逻辑了，因此不需要再初始化代理了
        // LogicV1(address(proxy)).initialize();                                    
    }

    function testOwner() view public {
        address getOwner = LogicV1(address(proxy)).owner();
        assertEq(getOwner, owner);
    }

    function testLogicV1Work(int128 _a, int128 _b) public {
        int256 result1 = LogicV1(address(proxy)).sum(_a, _b);
        int256 result2 = store.getResult();
        int256 result3 = int256(_a) + int256(_b);

        assertEq(result1, result2);
        assertEq(result2, result3);
    }

    function testOnlyOwnerCanUpdrade() public {

        vm.expectRevert();

        // 升级到 LogicV2 版本
        // 一定注意：在 OpenZeppelin 5.0.0 中，UUPSUpgradeable 合约不再包含 upgradeTo 方法，只有 upgradeToAndCall 方法
        LogicV1(address(proxy)).upgradeToAndCall(address(logicV2), "");      
    }

    function testLogicV2Work(int128 _a, int128 _b) public {
        vm.startPrank(owner);

        // bytes memory data = abi.encodeWithSelector(
        //     LogicV2.initiate.selector,                        
        //     address(owner),                              
        //     address(store)
        // );

        // note: 在合约升级到 LogicV2 后，不需要再调用 initiate() 重新初始化状态。
        // 合约升级的核心在于延续 LogicV1 中已有的状态变量和设置，只是通过 LogicV2 的新逻辑对其进行扩展或修改
        // 一旦在LogicV1中成功调用了initiate()并完成初始化，在升级到LogicV2后，再次调用initiate()会被阻止，因为代理合约已经记录了初始化状态。

        // 在 function upgradeToAndCall(address newImplementation, bytes memory data)， 第二个参数 data 参数用于在升级后立即调用新逻辑合约中的函数
        // 由于不需要再调用 initiate() 重新初始化状态，因此data传值为 “”
        LogicV1(address(proxy)).upgradeToAndCall(address(logicV2), "");

        vm.stopPrank();

        int256 result1 = LogicV2(address(proxy)).sub(_a, _b);
        int256 result2 = store.getResult();
        int256 result3 = int256(_a) - int256(_b);

        assertEq(result1, result2);
        assertEq(result2, result3);
    }


    function testStorage(int128 _a, int128 _b) public {
        LogicV1(address(proxy)).sum(_a, _b);
        int256 calculatedResult = int256(_a) + int256(_b);

        vm.startPrank(owner);
        LogicV1(address(proxy)).upgradeToAndCall(address(logicV2), "");
        vm.stopPrank();

        int256 storedResult = Store(LogicV2(address(proxy)).store()).getResult();

        assertEq(calculatedResult, storedResult);
    }
}