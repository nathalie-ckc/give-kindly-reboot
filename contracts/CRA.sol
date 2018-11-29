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

contract CRA {
  GiveKindlySystem gks;

  constructor (address _gksaddr) public {
    gks = GiveKindlySystem(_gksaddr);
  }

  // TODO: In future, CRA might have multiple staff working for it
  // TODO: For security, want to limit who can register as CRA. Need whitelist.
  function registerCRA(string _name, string _email, string _physAddr) public {
    gks.registerActor(msg.sender, uint8(GiveKindlySystem.ActorRole.CRA), _name, _email, _physAddr);
  }

  // TODO: Add functions to query anything CRA would be interested in
}
