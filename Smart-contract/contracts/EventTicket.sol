// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract EventTicket is ERC721Enumerable, Ownable {
    uint256 private _ticketCounter; // Counter to track ticket IDs
    address public eventContract; // Address of the event contract
    mapping(uint256 => uint256) public ticketEventMapping; // Maps token ID to event ID

    
    constructor(address _eventContract, string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        eventContract = _eventContract;
    }
    
    function mint(address _recipient, uint256 _eventId) external {
        require(msg.sender == eventContract, "Only event contract can mint tickets");
        _ticketCounter++;
        _safeMint(_recipient, _ticketCounter);
        ticketEventMapping[_ticketCounter] = _eventId;
    }
         
    function getTokensByAddress(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        require(tokenCount > 0, "No tickets owned by this address");

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    
    function getTokenForEvent(address _owner, uint256 _eventId) external view returns (uint256) {
        uint256 tokenCount = balanceOf(_owner);
        require(tokenCount > 0, "No tickets owned by this address");

        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_owner, i);
            if (ticketEventMapping[tokenId] == _eventId) {
                return tokenId;
            }
        }
        revert("No ticket found for this event");
    }
    
    function validateTicket(uint256 _tokenId, uint256 _eventId) external view returns (bool){
        require(ownerOf(_tokenId) != address(0), "Invalid ticket");
        require(ticketEventMapping[_tokenId] == _eventId, "Ticket does not match event");
        return true;
    }
}
