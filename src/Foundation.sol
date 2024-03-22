// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

contract Foundation {
    address public ownerAddress;
    address public withdrawalAddress;
    address public coWithdrawalAddress;
    mapping(address => bool) hasApproved;
    uint public approvalRequirement = 3;
    uint public approval;

    constructor(
        address _ownerAddress,
        address _withdrawalAddress,
        address _coWithdrawalAddress
    ) {
        ownerAddress = _ownerAddress;
        withdrawalAddress = _withdrawalAddress;
        coWithdrawalAddress = _coWithdrawalAddress;
        hasApproved[_ownerAddress] = false;
        hasApproved[_withdrawalAddress] = false;
        hasApproved[_coWithdrawalAddress] = false;
    }

    event Approve(address indexed sender, string message);
    event Withdraw(address indexed sender, uint value);

    function approve() external {
        require(
            !hasApproved[msg.sender],
            "You already approved the withdrawal"
        );
        if (
            msg.sender == ownerAddress ||
            msg.sender == withdrawalAddress ||
            msg.sender == coWithdrawalAddress
        ) {
            approval += 1;
        }
        hasApproved[msg.sender] = true;

        emit Approve(msg.sender, "has approved this withdrawal");
    }

    function withdraw() external {
        require(msg.sender == withdrawalAddress, "Invalid withdrawal address");
        (bool sent, ) = withdrawalAddress.call{value: address(this).balance}(
            ""
        );
        require(sent, "Withdrawal Failed");
        emit Withdraw(msg.sender, address(this).balance);
    }

    receive() external payable {}
}
