// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EventRSVP
 * @dev Solves the problem of people flaking on events.
 * Users stake ETH to RSVP.
 * If they check in, they get a 100% refund.
 * If they don't, the organizer keeps the ETH.
 *
 * Easy Deployment: No constructor arguments.
 */
contract EventRSVP {

    address public organizer;
    string public eventName;
    uint256 public depositAmount; // Wei required to RSVP
    uint256 public maxCapacity;
    
    // List of addresses that have RSVP'd
    address[] public attendeeList;
    
    // Mapping to track status
    mapping(address => bool) public hasRSVPed;
    mapping(address => bool) public hasCheckedIn;

    event EventCreated(string name, uint256 deposit, uint256 capacity);
    event NewRSVP(address indexed attendee);
    event CheckedIn(address indexed attendee, uint256 refundAmount);
    event FundsWithdrawn(uint256 amount);

    // Easy deploy: Owner is set, details set later.
    constructor() {
        organizer = msg.sender;
    }

    /**
     * @dev Configure the event details.
     */
    function createEvent(string memory _name, uint256 _depositAmount, uint256 _capacity) public {
        require(msg.sender == organizer, "Only organizer can create event");
        require(bytes(_name).length > 0, "Name required");
        require(_capacity > 0, "Capacity must be > 0");

        eventName = _name;
        depositAmount = _depositAmount;
        maxCapacity = _capacity;

        // Reset for new event
        delete attendeeList;
        
        emit EventCreated(_name, _depositAmount, _capacity);
    }

    /**
     * @dev User pays the deposit to reserve a spot.
     */
    function rsvp() public payable {
        require(bytes(eventName).length > 0, "No event active");
        require(msg.value == depositAmount, "Exact deposit amount required");
        require(!hasRSVPed[msg.sender], "Already RSVPed");
        require(attendeeList.length < maxCapacity, "Event is full");

        hasRSVPed[msg.sender] = true;
        hasCheckedIn[msg.sender] = false;
        attendeeList.push(msg.sender);

        emit NewRSVP(msg.sender);
    }

    /**
     * @dev Organizer checks in a user. This REFUNDS their deposit immediately.
     */
    function checkInUser(address _attendee) public {
        require(msg.sender == organizer, "Only organizer can check in");
        require(hasRSVPed[_attendee], "User did not RSVP");
        require(!hasCheckedIn[_attendee], "Already checked in / refunded");

        hasCheckedIn[_attendee] = true;

        // Refund the deposit
        (bool success, ) = _attendee.call{value: depositAmount}("");
        require(success, "Refund failed");

        emit CheckedIn(_attendee, depositAmount);
    }

    /**
     * @dev Withdraw deposits from people who did NOT show up.
     */
    function withdrawNoShowFunds() public {
        require(msg.sender == organizer, "Only organizer");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = organizer.call{value: balance}("");
        require(success, "Transfer failed");

        emit FundsWithdrawn(balance);
    }

    // --- View Functions ---
    function getStats() public view returns (uint256 rsvpCount, uint256 capacity, uint256 deposit) {
        return (attendeeList.length, maxCapacity, depositAmount);
    }

    function getAllAttendees() public view returns (address[] memory) {
        return attendeeList;
    }
}