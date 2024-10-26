// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import "../src/transparent/LogicV1.sol";
import "../src/transparent/LogicV2.sol";
import "../src/transparent/Store.sol";
import "../src/transparent/Proxy.sol";

contract TransparentTest is Test {
    LogicV1 public logicV1;
    LogicV2 public logicV2;
    Store public store;
    Proxy public proxy;
    address public admini = makeAddr("admini");

    function setUp() public {
        logicV1 = new LogicV1();
        logicV2 = new LogicV2();
        store = new Store();

        proxy = new Proxy(address(logicV1), address(store), admini);
    }

    function testProxyAdmini() view public {
        assertEq(proxy.admini(), admini);
    }

    function testLogicV1Work(int128 _a, int128 _b) public {
        bytes memory callData = abi.encodeWithSignature(
            "sum(int256,int256)",
            _a,
            _b
        );

        (bool success, bytes memory data) = address(proxy).call(callData);

        require(success, "failed!");

        int256 storedResult = store.getResult();
        int256 decodeData = abi.decode(data, (int256));
        int256 calculatedResult = int256(_a) + int256(_b);

        assertEq(storedResult, decodeData);
        assertEq(storedResult, calculatedResult);
    }

    function testOnlyAdminiCanUpgrade() public {
        vm.expectRevert("Only administrator can upgrade !");
        proxy.upgrade(address(logicV2));
    }

    function testLogicV2Work(int128 _a, int128 _b) public {
        vm.startPrank(admini);
        proxy.upgrade(address(logicV2));
        vm.stopPrank();

        bytes memory callData = abi.encodeWithSelector(
            LogicV2.sub.selector,
            _a,
            _b
        );

        (bool success, bytes memory data) = address(proxy).call(callData);

        require(success, "failed!");

        int256 storedResult = store.getResult();
        int256 decodeData = abi.decode(data, (int256));
        int256 calculatedResult = int256(_a) - int256(_b);

        assertEq(storedResult, decodeData);
        assertEq(storedResult, calculatedResult);
    }

    function testLogicChange() public {
        address logicAddress1 = proxy.logic();

        vm.startPrank(admini);
        proxy.upgrade(address(logicV2));
        vm.stopPrank();

        address logicAddress2 = proxy.logic();

        console.log("logicAddress1 = ", logicAddress1);
        console.log("logicAddress2 = ", logicAddress2);

        assert(logicAddress1 != logicAddress2);
    }

    function testLogicV1Destroyed(int128 _a, int128 _b) public {
        vm.startPrank(admini);
        proxy.upgrade(address(logicV2));
        vm.stopPrank();

        bytes memory callData = abi.encodeWithSelector(
            LogicV1.sum.selector,
            _a,
            _b
        );

        (bool success, ) = address(proxy).call(callData);

        vm.expectRevert();
        require(success, "call logicV1.sum() failed");
    }
}