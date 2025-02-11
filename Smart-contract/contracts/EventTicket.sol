// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


import "@openzeppelin/contracts/access/Ownable.sol";


contract EventTicket is ERC721Enumerable, Ownable(msg.sender) {
    uint256 private _ticketCounter;
    address public eventContract;

    constructor(address _eventContract, string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        eventContract = _eventContract;
    }

    function mint(address _recipient) external {
        require(msg.sender == eventContract, "Only event contract can mint tickets");
        ++_ticketCounter;
        _safeMint(_recipient, _ticketCounter);
    }
}
