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
    bool isRegistered;
    string name;
    string email;
    string physicalAddress;
  }

  // HACK: Be sure to update the enum counts below!
  enum ItemType { Car, Motorcycle, RV, Boat, Jewlry, Artwork }
  enum ItemState { AssignedToCharity, AssignedToAssessor, ListedForAuction, Sold }
  enum ActorRole { Donor, Charity, Auctioneer, CRA }

  // HACK for validity checking: Update these if adding to the enums!
  uint8 numItemTypes = 6;
  uint8 numItemStates = 4;
  uint8 numActorRoles = 4;

  uint32 public donationID = 0; // ID is index of next element to add to donationItemList array
  DonationItem[] public donationItemList;

  // Tradeoff: Storage to avoid iterating
  mapping (address => uint32[]) public donors2Items;
  mapping (address => uint32[]) public charities2Items;
  mapping (address => uint32[]) public assessors2Items;

  // All the registered actors
  mapping (address => GKActor) public participantList;

  function registerParticipant(address _participantAcct, uint8 _role, string _name, string _email, string _physAddr) public {
    require(_participantAcct != 0x0);
    require(_role < numActorRoles);
    participantList[_participantAcct] = GKActor(_participantAcct, _role, true, _name, _email, _physAddr);
  }

  function logDonation(address _donor, address _charity, uint8 _itemType, string _descr) public returns (uint32) {
    require(participantList[_donor].isRegistered);
    require(participantList[_charity].isRegistered);
    require(_itemType < numItemTypes);
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
    require(_itemID < donationID);
    require(participantList[_charity].isRegistered);
    require(donationItemList[_itemID].charity == _charity);
    require(participantList[_assessor].isRegistered);
    donationItemList[_itemID].assessor = _assessor;
    donationItemList[_itemID].itemState = uint8(ItemState.AssignedToAssessor);
    assessors2Items[_assessor].push(_itemID);
  }

  function itemUpForAuction(uint32 _itemID, address _assessor) public {
    require(_itemID < donationID);
    require(participantList[_assessor].isRegistered);
    require(donationItemList[_itemID].assessor == _assessor);
    donationItemList[_itemID].itemState = uint8(ItemState.ListedForAuction);
  }

  // Buyer doesn't need to be registered with GiveKindlySystem because they aren't relevant to taxes
  // Buyer would be registered with the Auctioneer
  function logCompletedAuction(uint32 _itemID, address _assessor, address _buyer, uint32 _value) public {
    require(_itemID < donationID);
    require(participantList[_assessor].isRegistered);
    require(donationItemList[_itemID].assessor == _assessor);
    donationItemList[_itemID].itemState = uint8(ItemState.Sold);
    donationItemList[_itemID].assessedValue = _value;
    donationItemList[_itemID].itemOwner = _buyer;
  }
}
