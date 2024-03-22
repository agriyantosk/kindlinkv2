// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "./Foundation.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Kindlink is Initializable {
    struct FoundationCandidate {
        address contractAddress;
        string name;
        uint yesVotes;
        uint noVotes;
    }

    struct ListedFoundation {
        address contractAddress;
        string name;
    }

    address public owner;
    mapping(address => FoundationCandidate) candidates;
    mapping(address => ListedFoundation) foundations;
    mapping(address => mapping(address => bool)) isVoted;
    mapping(address => uint) totalUsersDonations;

    event Donate(
        address indexed sender,
        address indexed foundation,
        uint value
    );
    event Vote(address indexed sender, address indexed foundation, bool vote);
    event WinsVote(address indexed foundation);
    event LoseVote(address indexed foundation);

    // constructor() {
    //     owner = msg.sender;
    // }

    function initialize() public initializer {
        owner = msg.sender;
    }

    function donate(address foundationAddress) external payable {
        require(
            foundationAddress != address(0),
            "Not allowing users to send ether to 0 address"
        );
        ListedFoundation storage foundation = foundations[foundationAddress];
        require(
            foundation.contractAddress == foundationAddress,
            "Foundation is not registered"
        );
        (bool sent, ) = foundationAddress.call{value: msg.value}("");
        require(sent, "Donation Failed");
        totalUsersDonations[msg.sender] += msg.value;

        emit Donate(msg.sender, foundationAddress, msg.value);
    }

    function vote(bool inputVote, address foundationAddress) external {
        // ini bagian pas dicek nya dulu
        require(
            totalUsersDonations[msg.sender] > 1 ether,
            "You must have a minimal total donations of 1 ETH to be able to contribute in the voting process"
        );
        require(
            !isVoted[foundationAddress][msg.sender],
            "You have already voted for this Foundation"
        );

        // ini bagian dia ngevote aja
        FoundationCandidate storage candidate = candidates[foundationAddress];

        if (inputVote) {
            candidate.yesVotes++;
        } else {
            candidate.noVotes++;
        }

        // ini bagian yang udah vote diitung
        isVoted[foundationAddress][msg.sender] = true;

        emit Vote(msg.sender, foundationAddress, inputVote);
    }

    function addCandidates(
        address foundationAddress,
        string memory name
    ) external onlyOwner {
        candidates[foundationAddress] = FoundationCandidate(
            foundationAddress,
            name,
            0,
            0
        );
    }

    function countVote(address foundationAddress) private view returns (bool) {
        FoundationCandidate storage candidate = candidates[foundationAddress];
        uint yesCount = candidate.yesVotes /
            (candidate.yesVotes + candidate.noVotes);
        uint noCount = candidate.noVotes /
            (candidate.yesVotes + candidate.noVotes);

        if (yesCount > noCount) {
            return true;
        } else {
            return false;
        }
    }

    function approveCandidate(
        address foundationAddress,
        string memory name,
        address coAddress
    ) external checkFoundationCandidate(foundationAddress) {
        if (countVote(foundationAddress)) {
            Foundation newFoundation = new Foundation(
                owner,
                foundationAddress,
                coAddress
            );
            foundations[address(newFoundation)] = ListedFoundation(
                address(newFoundation),
                name
            );
            delete candidates[foundationAddress];

            emit WinsVote(address(newFoundation));
        } else {
            delete candidates[foundationAddress];
            emit LoseVote(foundationAddress);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this action");
        _;
    }

    modifier checkFoundationCandidate(address foundationAddress) {
        FoundationCandidate storage candidate = candidates[foundationAddress];
        require(
            candidate.contractAddress == foundationAddress,
            "Foundation Candidate not found"
        );
        _;
    }
}
