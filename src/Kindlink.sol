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
        uint256 yesVotes;
        uint256 noVotes;
    }

    struct ListedFoundation {
        address contractAddress;
        string name;
    }

    address public owner;
    mapping(address => FoundationCandidate) candidates;
    mapping(address => ListedFoundation) foundations;
    mapping(address => mapping(address => bool)) isVoted;
    mapping(address => uint256) totalUsersDonations;

    event Donate(address indexed sender, address indexed foundation, uint256 value);
    event Vote(address indexed sender, address indexed foundation, bool vote);
    event WinsVote(address indexed foundation);
    event LoseVote(address indexed foundation);

    function initialize(address[] memory _foundationAddress, string[] memory _foundationName) public initializer {
        owner = msg.sender;
        require(_foundationAddress.length == _foundationName.length, "Foundation Address and Name length must be the same");
        for (uint256 i = 0; i < _foundationAddress.length; i++) {
            foundations[_foundationAddress[i]] = ListedFoundation(_foundationAddress[i], _foundationName[i]);
        }
    }

    function donate(address foundationAddress) external payable {
        require(foundationAddress != address(0), "Not allowing users to send ether to 0 address");
        ListedFoundation storage foundation = foundations[foundationAddress];
        require(foundation.contractAddress == foundationAddress, "Foundation is not registered");
        (bool sent,) = foundationAddress.call{value: msg.value}("");
        require(sent, "Donation Failed");
        totalUsersDonations[msg.sender] += msg.value;

        emit Donate(msg.sender, foundationAddress, msg.value);
    }

    function vote(bool inputVote, address foundationAddress) external {
        // ini bagian pas dicek nya dulu
        require(
            totalUsersDonations[msg.sender] >= 1 ether,
            "You must have a minimal total donations of 1 ETH to be able to contribute in the voting process"
        );
        require(!isVoted[foundationAddress][msg.sender], "You have already voted for this Foundation");

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

    function addCandidates(address foundationAddress, string memory name) external onlyOwner {
        require(foundationAddress != address(0), "Not allowing users to send ether to 0 address");
        candidates[foundationAddress] = FoundationCandidate(foundationAddress, name, 0, 0);
    }

    function countVote(address foundationAddress) private view returns (bool) {
        FoundationCandidate storage candidate = candidates[foundationAddress];
        uint256 yesCount = candidate.yesVotes / (candidate.yesVotes + candidate.noVotes);
        uint256 noCount = candidate.noVotes / (candidate.yesVotes + candidate.noVotes);

        if (yesCount > noCount) {
            return true;
        } else {
            return false;
        }
    }

    function approveCandidate(address foundationAddress, string memory name, address coAddress)
        external
        checkFoundationCandidate(foundationAddress)
    {
        if (countVote(foundationAddress)) {
            Foundation newFoundation = new Foundation(owner, foundationAddress, coAddress);
            foundations[address(newFoundation)] = ListedFoundation(address(newFoundation), name);
            delete candidates[foundationAddress];

            emit WinsVote(address(newFoundation));
        } else {
            delete candidates[foundationAddress];
            emit LoseVote(foundationAddress);
        }
    }

    function getCandidates(address foundationAddress)
        external
        view
        returns (address, string memory, uint256, uint256)
    {
        return (
            candidates[foundationAddress].contractAddress,
            candidates[foundationAddress].name,
            candidates[foundationAddress].yesVotes,
            candidates[foundationAddress].noVotes
        );
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do this action");
        _;
    }

    modifier checkFoundationCandidate(address foundationAddress) {
        FoundationCandidate storage candidate = candidates[foundationAddress];
        require(candidate.contractAddress == foundationAddress, "Foundation Candidate not found");
        _;
    }
}
