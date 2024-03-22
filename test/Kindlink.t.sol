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

    address foundationAddress = makeAddr("foundationAddress");
    string foundationName = "KitaBisa";

    address[] foundationAddresses;
    string[] foundationNames;

    function setUp() public {
        foundation = new Foundation(owner, wdAddress, coWdAddress);
        kindlink = new Kindlink();
        proxy = new ERC1967Proxy(address(kindlink), "");

        foundationAddresses.push(foundationAddress);
        foundationNames.push(foundationName);

        vm.prank(owner);
        Kindlink(address(proxy)).initialize(
            foundationAddresses,
            foundationNames
        );
    }

    function testOwner() public view {
        assertEq(Kindlink(address(proxy)).owner(), owner);
    }

    function testAddCandidateOnlyOwnerFailed() public {
        vm.expectRevert("Only owner can do this action");
        Kindlink(address(proxy)).addCandidates(foundationAddress, "KitaBisa");
    }

    function testAddCandidate() public {
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
        address _foundationAddress,
        string memory _foundationName
    ) public {
        // address foundationAddress = makeAddr("foundationAddress");
        // string memory foundationName = "KitaBisa";
        vm.assume(_foundationAddress != address(0));
        vm.prank(owner);
        Kindlink(address(proxy)).addCandidates(
            _foundationAddress,
            _foundationName
        );
        (
            address contractAddress,
            string memory name,
            uint yesVotes,
            uint noVotes
        ) = Kindlink(address(proxy)).getCandidates(_foundationAddress);
        assertEq(contractAddress, _foundationAddress);
        assertEq(name, _foundationName);
        assertEq(yesVotes, 0);
        assertEq(noVotes, 0);
    }

    function testVoteLessEtherFailed() public {
        bool inputVote = true;
        address user1 = makeAddr("user1");
        vm.prank(user1);
        vm.expectRevert(
            "You must have a minimal total donations of 1 ETH to be able to contribute in the voting process"
        );
        Kindlink(address(proxy)).vote(inputVote, foundationAddress);
    }

    modifier cheat() {
        vm.startPrank(owner);
        Kindlink(address(proxy)).addCandidates(
            foundationAddress,
            foundationName
        );

        _;
    }

    function testVoteIsVotedFailed() public {
        address user1 = makeAddr("user1");
        vm.deal(user1, 10 ether);

        vm.prank(user1);
        Kindlink(address(proxy)).donate{value: 1 ether}(foundationAddresses[0]);

        vm.prank(owner);
        Kindlink(address(proxy)).addCandidates(
            foundationAddress,
            foundationName
        );

        vm.startPrank(user1);
        Kindlink(address(proxy)).vote(true, foundationAddress);
        vm.expectRevert("You have already voted for this Foundation");
        Kindlink(address(proxy)).vote(false, foundationAddress);
        vm.stopPrank();
    }

    function testVote() public {
        address user1 = makeAddr("user1");
        vm.deal(user1, 10 ether);

        vm.prank(user1);
        Kindlink(address(proxy)).donate{value: 1 ether}(foundationAddresses[0]);

        vm.prank(owner);
        Kindlink(address(proxy)).addCandidates(
            foundationAddress,
            foundationName
        );

        vm.prank(user1);
        Kindlink(address(proxy)).vote(true, foundationAddress);

        (
            address contractAddress,
            string memory name,
            uint yesVotes,
            uint noVotes
        ) = Kindlink(address(proxy)).getCandidates(foundationAddress);

        assertEq(contractAddress, foundationAddress);
        assertEq(name, "KitaBisa");
        assertEq(yesVotes, 1);
        assertEq(noVotes, 0);
    }

    function testDonateFailed() public {
        address user1 = makeAddr("user1");
        address falseFoundationAddress = makeAddr("falseFoundationAddress");
        vm.deal(user1, 10 ether);

        vm.prank(user1);
        vm.expectRevert("Foundation is not registered");
        Kindlink(address(proxy)).donate{value: 1 ether}(falseFoundationAddress);
    }

    function testDonate() public {
        address user1 = makeAddr("user1");
        vm.deal(user1, 10 ether);

        vm.prank(user1);
        Kindlink(address(proxy)).donate{value: 1 ether}(foundationAddresses[0]);

        assertEq(foundationAddresses[0].balance, 1 ether);
    }

    function testApproveCandidateNotFoundFailed() public {
        address falseFoundationAddress = makeAddr("falseFoundationAddress");
        string memory name = "KitaBisa";
        address coWithdrawalAddress = makeAddr("coWithdrawalAddress");
        vm.expectRevert("Foundation Candidate not found");
        Kindlink(address(proxy)).approveCandidate(
            falseFoundationAddress,
            name,
            coWithdrawalAddress
        );
    }
}
