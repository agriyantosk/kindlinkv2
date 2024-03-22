// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import {Foundation} from "./Foundation.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Kindlink is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct FoundationCandidate {
        address withdrawalAddress;
        string name;
        address coWithdrawalAddress;
        uint256 yesVotes;
        uint256 noVotes;
    }

    struct ListedFoundation {
        address withdrawalAddress;
        string name;
    }

    mapping(address => FoundationCandidate) candidates;
    mapping(address => ListedFoundation) foundations;
    mapping(address => mapping(address => bool)) isVoted;
    mapping(address => uint256) totalUsersDonations;

    event Donate(
        address indexed sender,
        address indexed foundation,
        uint256 value
    );
    event Vote(address indexed sender, address indexed foundation, bool vote);
    event WinsVote(address indexed foundation);
    event LoseVote(address indexed foundation);

    function initialize(
        address[] memory _withdrawalAddress,
        string[] memory _foundationName
    ) public initializer {
        __Ownable_init(msg.sender); //owner = msg.sender;
        __UUPSUpgradeable_init(); //* To tell that this contract is upgradeable.
        require(
            _withdrawalAddress.length == _foundationName.length,
            "Foundation Address and Name length must be the same"
        );
        for (uint256 i = 0; i < _withdrawalAddress.length; i++) {
            foundations[_withdrawalAddress[i]] = ListedFoundation(
                _withdrawalAddress[i],
                _foundationName[i]
            );
        }
    }

    function donate(address withdrawalAddress) external payable {
        require(
            withdrawalAddress != address(0),
            "Not allowing users to send ether to 0 address"
        );
        ListedFoundation storage foundation = foundations[withdrawalAddress];
        require(
            foundation.withdrawalAddress == withdrawalAddress,
            "Foundation is not registered"
        );
        (bool sent, ) = withdrawalAddress.call{value: msg.value}("");
        require(sent, "Donation Failed");
        totalUsersDonations[msg.sender] += msg.value;

        emit Donate(msg.sender, withdrawalAddress, msg.value);
    }

    function vote(bool inputVote, address withdrawalAddress) external {
        // ini bagian pas dicek nya dulu
        require(
            totalUsersDonations[msg.sender] >= 1 ether,
            "You must have a minimal total donations of 1 ETH to be able to contribute in the voting process"
        );
        require(
            !isVoted[withdrawalAddress][msg.sender],
            "You have already voted for this Foundation"
        );

        // ini bagian dia ngevote aja
        FoundationCandidate storage candidate = candidates[withdrawalAddress];

        if (inputVote) {
            candidate.yesVotes++;
        } else {
            candidate.noVotes++;
        }

        // ini bagian yang udah vote diitung
        isVoted[withdrawalAddress][msg.sender] = true;

        emit Vote(msg.sender, withdrawalAddress, inputVote);
    }

    function addCandidates(
        address withdrawalAddress,
        string memory name,
        address coWithdrawalAddress
    ) external onlyOwner {
        require(
            withdrawalAddress != address(0),
            "Not allowing users to send ether to 0 address"
        );
        candidates[withdrawalAddress] = FoundationCandidate(
            withdrawalAddress,
            name,
            coWithdrawalAddress,
            0,
            0
        );
    }

    function countVote(address withdrawalAddress) private view returns (bool) {
        FoundationCandidate storage candidate = candidates[withdrawalAddress];
        uint256 yesCount = candidate.yesVotes;
        uint256 noCount = candidate.noVotes;

        if (yesCount > noCount) {
            return true;
        } else {
            return false;
        }
    }

    function approveCandidate(
        address withdrawalAddress
    ) external checkFoundationCandidate(withdrawalAddress) {
        if (countVote(withdrawalAddress)) {
            Foundation newFoundation = new Foundation(
                owner(),
                withdrawalAddress,
                candidates[withdrawalAddress].coWithdrawalAddress
            );
            foundations[address(newFoundation)] = ListedFoundation(
                address(newFoundation),
                candidates[withdrawalAddress].name
            );
            delete candidates[withdrawalAddress];

            emit WinsVote(address(newFoundation));
        } else {
            delete candidates[withdrawalAddress];
            emit LoseVote(withdrawalAddress);
        }
    }

    function getCandidates(
        address withdrawalAddress
    )
        external
        view
        returns (address, string memory, address, uint256, uint256)
    {
        return (
            candidates[withdrawalAddress].withdrawalAddress,
            candidates[withdrawalAddress].name,
            candidates[withdrawalAddress].coWithdrawalAddress,
            candidates[withdrawalAddress].yesVotes,
            candidates[withdrawalAddress].noVotes
        );
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner() {}

    modifier checkFoundationCandidate(address withdrawalAddress) {
        FoundationCandidate storage candidate = candidates[withdrawalAddress];
        require(
            candidate.withdrawalAddress == withdrawalAddress,
            "Foundation Candidate not found"
        );
        _;
    }
}
