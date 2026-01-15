// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SharedTreasury
 * @dev A joint wallet for teams, families, or roommates.
 * 1. Admin adds "Members".
 * 2. Members can deposit funds.
 * 3. Members can pay bills directly from the contract.
 *
 * Easy Deployment: No constructor arguments.
 */
contract SharedTreasury is Ownable {

    mapping(address => bool) public isMember;
    
    struct Transaction {
        address who;     // Which member initiated it
        address to;      // Who got the money
        uint256 amount;
        string reason;
        uint256 timestamp;
    }

    Transaction[] public history;

    event Deposit(address indexed from, uint256 amount);
    event PaymentSent(address indexed by, address indexed to, uint256 amount, string reason);
    event MemberAdded(address member);
    event MemberRemoved(address member);

    // Deployer is automatically the first member and owner
    constructor() Ownable(msg.sender) {
        isMember[msg.sender] = true;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Not a member of this treasury");
        _;
    }

    /**
     * @dev Add a new person to the shared wallet.
     */
    function addMember(address _newMember) public onlyOwner {
        require(_newMember != address(0), "Invalid address");
        isMember[_newMember] = true;
        emit MemberAdded(_newMember);
    }

    /**
     * @dev Remove a person.
     */
    function removeMember(address _member) public onlyOwner {
        isMember[_member] = false;
        emit MemberRemoved(_member);
    }

    /**
     * @dev Deposit funds into the shared pot.
     */
    function deposit() public payable {
        require(msg.value > 0, "Deposit must be > 0");
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Pay a bill or send money to someone.
     * Only members can do this.
     */
    function payBill(address payable _to, uint256 _amount, string memory _reason) public onlyMember {
        require(address(this).balance >= _amount, "Not enough funds in treasury");
        require(_to != address(0), "Invalid receiver");

        // Record history BEFORE transfer
        history.push(Transaction({
            who: msg.sender,
            to: _to,
            amount: _amount,
            reason: _reason,
            timestamp: block.timestamp
        }));

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed");

        emit PaymentSent(msg.sender, _to, _amount, _reason);
    }

    // --- View Functions ---

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTransactionCount() public view returns (uint256) {
        return history.length;
    }

    // Return the last 10 transactions (or fewer)
    function getRecentTransactions() public view returns (Transaction[] memory) {
        uint256 length = history.length;
        uint256 returnCount = length < 10 ? length : 10;
        Transaction[] memory recent = new Transaction[](returnCount);
        
        for (uint256 i = 0; i < returnCount; i++) {
            recent[i] = history[length - 1 - i];
        }
        return recent;
    }
}