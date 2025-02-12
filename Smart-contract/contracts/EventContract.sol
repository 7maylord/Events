// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "./EventTicket.sol";

contract EventContract {
    enum EventType {
        free,
        paid
    }

    event EventCreated(uint256 indexed _id, address indexed _organizer);
    event TicketPurchased(uint256 indexed _eventId, address indexed _buyer);
    event TicketMinted(uint256 indexed _eventId, address indexed_recipient, uint256 _tokenId);
    event AttendanceVerified(uint256 indexed eventId, address indexed attendee);

    struct EventDetails {
        string _title;
        string _description;
        uint256 _startDate;
        uint256 _endDate;
        EventType _type;        
        uint256 _ticketPrice;
        uint32 _expectedGuestCount;
        uint32 _registeredGuestCount;
        uint32 _verifiedGuestCount;
        address _organizer;
        address _ticketAddress;
    }

    uint256 public event_count;
    mapping(uint256 => EventDetails) public events;
    mapping(address => mapping(uint256 => bool)) public hasRegistered;

    // write functions
    // create event
    function createEvent(
        string memory _title,
        string memory _desc,
        uint256 _startDate,
        uint256 _endDate,
        EventType _type,
        uint256 _ticketPrice,
        uint32 _egc  
    ) external {

        uint256 _eventId = event_count + 1;

        require(msg.sender != address(0), 'UNAUTHORIZED CALLER');

        require(_startDate > block.timestamp, 'START DATE MUST BE IN FUTURE');

        require(_startDate < _endDate, 'END DATE MUST BE GREATER');

        require(_type == EventType.free || _ticketPrice > 0, "PAID EVENTS MUST HAVE TICKET PRICE > 0");


        // Change??
        events[_eventId] = EventDetails ({
            _title: _title,
            _description: _desc,
            _startDate: _startDate,
            _endDate: _endDate,
            _type: _type,
            _ticketPrice: _ticketPrice,
            _expectedGuestCount: _egc,
            _registeredGuestCount: 0,
            _verifiedGuestCount: 0,
            _organizer: msg.sender,
            _ticketAddress: address(0)
        });

        event_count = _eventId;
        emit EventCreated(_eventId, msg.sender);
    }

    // register for an event
    function registerForEvent(uint256 _eventId) external payable {

        require(msg.sender != address(0), 'INVALID ADDRESS');

        require(_eventId <= event_count && _eventId != 0, 'No Event Exist');
        
        // get event details
        EventDetails memory _eventInstance = events[_eventId];

        require(_eventInstance._endDate > block.timestamp, 'EVENT HAS ENDED');

        require(_eventInstance._registeredGuestCount < _eventInstance._expectedGuestCount, 'REGISTRATION CLOSED');

        require(!hasRegistered[msg.sender][_eventId], 'ALREADY REGISTERED');

        if (_eventInstance._type == EventType.paid) {
            require(msg.value >= _eventInstance._ticketPrice, "INSUFFICIENT FUNDS");
            //Implement funds transfer of funds to contract after creating withdrawal function for organizer
            payable(_eventInstance._organizer).transfer(msg.value);
            _eventInstance._registeredGuestCount++;
        }     
    
        else {
            // update registered event guest count
            _eventInstance._registeredGuestCount++;          
        }
        // updated has reg mapping
        hasRegistered[msg.sender][_eventId] = true;
        // updated has events mapping
        events[_eventId] = _eventInstance;
        emit TicketPurchased(_eventId, msg.sender);
        // Mint NFT ticket to msg.sender
        EventTicket(_eventInstance._ticketAddress).mint(msg.sender, _eventId);
       
    } 

    function createEventTicket (uint256 _eventId, string memory _ticketname, string memory _ticketSymbol) external {

        require(_eventId <= event_count && _eventId != 0, "No Event Exist");
        
        EventDetails memory _eventInstance = events[_eventId];

        require(msg.sender == _eventInstance._organizer, 'ONLY ORGANIZER');

        require(_eventInstance._ticketAddress == address(0), 'ALREADY CREATED');

        EventTicket newTicket = new EventTicket(address(this), _ticketname, _ticketSymbol);

        _eventInstance._ticketAddress = address(newTicket);

        events[_eventId] = _eventInstance;

    }   

    // confirm/validate of tickets
    function validateTicket(uint256 _eventId, address _attendee) external {
        require(_eventId > 0 && _eventId <= event_count, "No Event");
        EventDetails memory _eventInstance = events[_eventId];
        require(_eventInstance._organizer == msg.sender, "ONLY ORGANIZER CAN VALIDATE");

        uint256 tokenId = EventTicket(_eventInstance._ticketAddress).getTokenForEvent(_attendee, _eventId);
        EventTicket(_eventInstance._ticketAddress).validateTicket(tokenId, _eventId);

        _eventInstance._verifiedGuestCount++;
        events[_eventId] = _eventInstance;
        emit AttendanceVerified(_eventId, _attendee);
    }
}