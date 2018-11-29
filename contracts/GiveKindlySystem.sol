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

contract GiveKindlySystem {
  enum ItemType { Car, Motorcycle, RV, Boat, Jewlry, Artwork }

  enum ItemState { AssignedToCharity, AssignedToAssessor, ListedForAuction, Sold }

  enum ActorRole { Donor, Charity, Auctioneer, CRA }

  // itemID will be index into donation item array
  struct DonationItem {
    address donor;
    address charity;
    address assessor;
    address itemOwner;
    uint32 assessedValue;
    uint8 itemState;
    uint8 itemType;
    string description;
  }

  struct GKActor {
    address ethAccount;
    uint8 role;
    string name;
    string email;
    string physicalAddress;
  }

  // Tradeoff: Storage to avoid iterating
  mapping (address => uint32[]) public donors2Items;
  mapping (address => uint32[]) public charities2Items;
  mapping (address => uint32[]) public assessors2Items;

  DonationItem[] public donationItemList;
  uint32 public donationID = 0; // ID is index in donationItemList array

  mapping (address => GKActor) public participantList;

  function registerParticipant(address _participantAcct, uint8 _role, string _name, string _email, string _physAddr) public {
    participantList[_participantAcct] = GKActor(_participantAcct, _role, _name, _email, _physAddr);
  }

  function logDonation(address _donor, address _charity, uint8 _itemType, string _descr) public returns (uint32) {
    uint32 retval = donationID;
    donationItemList.push(DonationItem(_donor, _charity, 0, 0, 0, uint8(ItemState.AssignedToCharity), _itemType, _descr));
    donors2Items[_donor].push(donationID);
    charities2Items[_charity].push(donationID);
    donationID++;
    // TODO: emit event to notify the charity and tell it the itemID
    return retval;
  }

  function getDonationCount() public view returns (uint32) {
    return donationID;
  }

  function assignAssessor(uint32 _itemID, address _charity, address _assessor) public {
    require(donationItemList[_itemID].charity == _charity);
    donationItemList[_itemID].assessor = _assessor;
    donationItemList[_itemID].itemState = uint8(ItemState.AssignedToAssessor);
    assessors2Items[_assessor].push(_itemID);
  }

  function itemUpForAuction(uint32 _itemID, address _assessor) public {
    require(donationItemList[_itemID].assessor == _assessor);
    donationItemList[_itemID].itemState = uint8(ItemState.ListedForAuction);
  }

  function logCompletedAuction(uint32 _itemID, address _assessor, address _buyer, uint32 _value) public {
    require(donationItemList[_itemID].assessor == _assessor);
    donationItemList[_itemID].itemState = uint8(ItemState.Sold);
    donationItemList[_itemID].assessedValue = _value;
    donationItemList[_itemID].itemOwner = _buyer;
  }
}
