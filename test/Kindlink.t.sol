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

    function testOwner() public view {
        assertEq(Kindlink(address(proxy)).owner(), owner);
    }

    function testAddCandidateOnlyOwnerFailed() public {
        address foundationAddress = makeAddr("foundationAddress");
        vm.expectRevert("Only owner can do this action");
        Kindlink(address(proxy)).addCandidates(foundationAddress, "KitaBisa");
    }

    function testAddCandidate() public {
        address foundationAddress = makeAddr("foundationAddress");
        string memory foundationName = "KitaBisa";
        vm.prank(owner);
        Kindlink(address(proxy)).addCandidates(
            foundationAddress,
            foundationName
        );
        (
            address contractAddress,
            string memory name,
            uint yesVotes,
            uint noVotes
        ) = Kindlink(address(proxy)).getCandidates(foundationAddress);
        assertEq(contractAddress, foundationAddress);
        assertEq(name, foundationName);
        assertEq(yesVotes, 0);
        assertEq(noVotes, 0);
    }

    function testAddCandidateFuzz(
        address foundationAddress,
        string memory foundationName
    ) public {
        // address foundationAddress = makeAddr("foundationAddress");
        // string memory foundationName = "KitaBisa";
        vm.prank(owner);
        Kindlink(address(proxy)).addCandidates(
            foundationAddress,
            foundationName
        );
        (
            address contractAddress,
            string memory name,
            uint yesVotes,
            uint noVotes
        ) = Kindlink(address(proxy)).getCandidates(foundationAddress);
        assertEq(contractAddress, foundationAddress);
        assertEq(name, foundationName);
        assertEq(yesVotes, 0);
        assertEq(noVotes, 0);
    }

    function testVoteLessEtherFailed() public {
        address foundationAddress = makeAddr("foundationAddress");
        bool inputVote = true;
        address user1 = makeAddr("user1");
        vm.prank(user1);
        vm.expectRevert(
            "You must have a minimal total donations of 1 ETH to be able to contribute in the voting process"
        );
        Kindlink(address(proxy)).vote(inputVote, foundationAddress);
    }

    modifier cheat() {
        address foundationAddress = makeAddr("foundationAddress");
        string memory foundationName = "KitaBisa";
        vm.startPrank(owner);
        Kindlink(address(proxy)).addCandidates(
            foundationAddress,
            foundationName
        );

        _;
    }

    function testVoteIsVotedFailed() public {
        address user1 = makeAddr("user1");
        vm.deal(user1, 1 ether);
        // Kindlink(address(proxy)).donate(foundationAdress);
    }
}
