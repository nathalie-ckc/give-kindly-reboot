/*
The MIT License (MIT)

Copyright (c) 2018 Nathalie C. Chan King Choy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.4.18;

import "./GiveKindlySystem.sol";

contract Charity {
  GiveKindlySystem gks;

  function Charity(address _gksaddr) public {
    gks = GiveKindlySystem(_gksaddr);
  }

  // TODO: In future, a charity might have multiple staff working for it
  function registerCharity(string _name, string _email, string _physAddr) public {
    gks.registerParticipant(msg.sender, uint8(GiveKindlySystem.ActorRole.Charity), _name, _email, _physAddr);
  }

  function assignAssessor(uint32 _itemID, address _assessor) public {
    gks.assignAssessor(_itemID, msg.sender, _assessor);
  }

  // TODO: Add function to query the donations for the calling charity
}
