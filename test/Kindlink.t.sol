// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";
import {Kindlink} from "../src/Kindlink.sol";
import {Foundation} from "../src/Foundation.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract KindlinkTest is Test {
    Kindlink kindlink;
    Foundation foundation;
    ERC1967Proxy proxy;

    address owner = makeAddr("owner");
    address wdAddress = makeAddr("wdAddress");
    address coWdAddress = makeAddr("coWdAddress");

    function setUp() public {
        kindlink = new Kindlink();
        foundation = new Foundation(owner, wdAddress, coWdAddress);
        proxy = new ERC1967Proxy(address(kindlink), "");
        vm.prank(owner);
        Kindlink(address(proxy)).initialize();
    }

    function testOwner() public {
        assert(Kindlink(address(proxy)).owner() == owner);
    }
}
