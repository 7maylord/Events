// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "./EventTicket.sol";

contract EventContract {
    enum EventType {
        free,
        paid
    }

    event EventCreated (uint256 indexed _id, address indexed _organizer);
    event TicketPurchased(uint256 indexed _eventId, address indexed _buyer);
    event TicketMinted(uint256 indexed _eventId, address _recipient, uint256 _tokenId);
    event AttendanceVerified(uint256 indexed eventId, address indexed attendee);



      struct EventDetails {
        string _title;
        string _description;
        uint256 _startDate;
        uint256 _endDate;
        EventType _type;
        uint32 _expectedGuestCount;
        uint32 _registeredGuestCount;
        uint32 _verifiedGuestCount;
        address _organizer;
        address _ticketAddress;
        uint256 _ticketPrice;
    }

    uint256 public event_count;
    mapping(uint256 => EventDetails) public events;
    mapping(address => mapping(uint256 => bool)) hasRegistered;

    // write functions
    // create event
    function createEvent(
        string memory _title,
        string memory _desc,
        uint256 _startDate,
        uint256 _endDate,
        EventType _type,
        uint32 _egc,    
        uint256 _ticketPrice
    ) external {

        uint256 _eventId = event_count + 1;

        require(msg.sender != address(0), 'UNAUTHORIZED CALLER');

        require(_startDate > block.timestamp, 'START DATE MUST BE IN FUTURE');

        require(_startDate < _endDate, 'END DATE MUST BE GREATER');

        // Change??
        EventDetails memory _updatedEvent = EventDetails ({
            _title: _title,
            _description: _desc,
            _startDate: _startDate,
            _endDate: _endDate,
            _type: _type,
            _expectedGuestCount: _egc,
            _registeredGuestCount: 0,
            _verifiedGuestCount: 0,
            _organizer: msg.sender,
            _ticketAddress: address(0),
            _ticketPrice: _ticketPrice
        });

        events[_eventId] = _updatedEvent;

        event_count = _eventId;

        emit EventCreated(_eventId, msg.sender);
    }

    // register for an event
    function registerForEvent(uint256 _event_id) external payable {

        require(msg.sender != address(0), 'INVALID ADDRESS');

        require(_event_id <= event_count && _event_id != 0, 'EVENT DOES NoT EXIST');
        
        // get event details
        EventDetails memory _eventInstance = events[_event_id];

        require(_eventInstance._endDate > block.timestamp, 'EVENT HAS ENDED');

        require(_eventInstance._registeredGuestCount < _eventInstance._expectedGuestCount, 'REGISTRATION CLOSED');

        require(!hasRegistered[msg.sender][_event_id], 'ALREADY REGISTERED');

        if (_eventInstance._type == EventType.paid) {
            //call internal func. for ticket purchase
            purchaseTicket(_event_id);
        }
        else {
            // update registered event guest count
            _eventInstance._registeredGuestCount++;
            
            // updated has reg struct
            hasRegistered[msg.sender][_event_id] = true;

            // mint ticket to user
            mint(_event_id, msg.sender);

        }
    } 

       // Purchase a ticket for a paid event
    function purchaseTicket(uint256 _eventId) internal {
        EventDetails memory _eventInstance = events[_eventId];

        require(_eventInstance._type == EventType.paid, "EVENT IS NOT PAID");
        require(_eventInstance._ticketPrice > 0, "INVALID TICKET PRICE");
        require(msg.value >= _eventInstance._ticketPrice, "INSUFFICIENT FUNDS");

        payable(_eventInstance._organizer).transfer(msg.value); // Transfer payment to organizer

        _eventInstance._registeredGuestCount++;
        hasRegistered[msg.sender][_eventId] = true;

        emit TicketPurchased(_eventId, msg.sender);
        // Mint NFT ticket to msg.sender
        // EventTicket(_eventInstance._ticketAddress).mint(msg.sender);
        mint(_eventId, msg.sender);
    }


    function createEventTicket (uint256 _eventId, string memory _ticketname, string memory _ticketSymbol) external {

        require(_eventId <= event_count && _eventId != 0, "EVENT DOESN'T EXIST");
        
        EventDetails memory _eventInstance = events[_eventId];

        require(msg.sender == _eventInstance._organizer, 'ONLY ORGANIZER CAN CREATE');

        require(_eventInstance._ticketAddress == address(0), 'TICKET ALREADY CREATED');

        EventTicket newTicket = new EventTicket(address(this), _ticketname, _ticketSymbol);

        events[_eventId]._ticketAddress = address(newTicket);

        // _eventInstance._ticketAddress = address(newTicket);

    }

    function mint(uint256 _eventId, address _recipient) internal {
        EventDetails memory _eventInstance = events[_eventId];
        require(_eventInstance._ticketAddress != address(0), "TICKET CONTRACT NOT CREATED");

        EventTicket(_eventInstance._ticketAddress).mint(_recipient);
        emit TicketMinted(_eventId, _recipient, _eventInstance._registeredGuestCount);
   
    }

    // confirm/validate of tickets
    function validateTicket(uint256 _eventId, address _attendee) external {
        require(_eventId > 0 && _eventId <= event_count, "EVENT DOESN'T EXIST");

        EventDetails memory _eventInstance = events[_eventId];
        require(_eventInstance._organizer == msg.sender, 'ONLY ORGANIZER CAN VALIDATE');
        require(_eventInstance._ticketAddress != address(0), 'TICKET CONTRACT NOT CREATED');
        require(EventTicket(_eventInstance._ticketAddress).ownerOf(_tokenId) != address(0), 'INVALID TICKET');
        EventTicket(_eventInstance._ticketAddress).validateTicket(_tokenId);
        _eventInstance._verifiedGuestCount++;

        emit AttendanceVerified(_eventId, _attendee);
    }


    // read functions

    // function getEventDetails(uint256 _eventId) external view returns (EventDetails memory) {
    //     return events[_eventId];
    // }

    function getEventDetails(uint256 _eventId) external view returns (
    string memory title,
    string memory description,
    uint256 startDate,
    uint256 endDate,
    EventType eventType,
    uint32 expectedGuestCount,
    uint32 registeredGuestCount,
    uint32 verifiedGuestCount,
    address organizer,
    address ticketContract,
    uint256 ticketPrice
) {
    require(_eventId <= event_count && _eventId != 0, "EVENT DOESN'T EXIST");

    EventDetails memory eventInstance = events[_eventId];

    return (
        eventInstance._title,
        eventInstance._description,
        eventInstance._startDate,
        eventInstance._endDate,
        eventInstance._type,
        eventInstance._expectedGuestCount,
        eventInstance._registeredGuestCount,
        eventInstance._verifiedGuestCount,
        eventInstance._organizer,
        eventInstance._ticketAddress,
        eventInstance.ticketPrice
    );
}
    function isRegisteredForEvent(address _attendee, uint256 _eventId) external view returns (bool) {
    require(_eventId <= event_count && _eventId != 0, "EVENT DOESN'T EXIST");
    return hasRegistered[_attendee][_eventId];
}
}