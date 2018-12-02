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

  uint32 public numActorsRegistered = 0; // For DEBUG
  uint32 public donationID = 0; // ID is index of next element to add to donationItemList array
  DonationItem[] public donationItemList;

  // Tradeoff: Storage to avoid iterating
  mapping (address => uint32[]) public donors2Items;
  mapping (address => uint32[]) public charities2Items;
  mapping (address => uint32[]) public assessors2Items;

  // All the registered actors
  mapping (address => GKActor) public actorList;

  //==================================================
  // Don't make these functions internal because the intent is to have the role functions
  // live in separate contracts for each role. But I have merged all into 1 contract because
  // of the issue with Ganache having VM error when I call a function in another contract &
  // I don't want to restrict myself to testing on just Remix JavaScript VM or Rinkeby
  //==================================================

  function getDonationCount() public view returns (uint32) {
    return donationID;
  }

  // TODO: Add getter functions that return the whole array of donors, charities & assessors to items

  function registerActor(address _actorAcct, uint8 _role, string _name, string _email, string _physAddr) public {
    require(_actorAcct != 0x0);
    require(_role < numActorRoles);
    actorList[_actorAcct] = GKActor(_actorAcct, _role, true, _name, _email, _physAddr);
    numActorsRegistered++;
  }

  function logDonation(address _donor, address _charity, uint8 _itemType, string _descr) public returns (uint32) {
    require(actorList[_donor].isRegistered);
    require(actorList[_charity].isRegistered);
    require(_itemType < numItemTypes);
    uint32 retval = donationID;
    donationItemList.push(DonationItem(_donor, _charity, 0, 0, uint8(ItemState.AssignedToCharity), _itemType, _descr));
    donors2Items[_donor].push(donationID);
    charities2Items[_charity].push(donationID);
    donationID++;
    // TODO: emit event to notify the charity and tell it the itemID
    return retval;
  }

  function assignAssessor(uint32 _itemID, address _charity, address _assessor) public {
    require(_itemID < donationID);
    require(actorList[_charity].isRegistered);
    require(donationItemList[_itemID].charity == _charity);
    require(actorList[_assessor].isRegistered);
    donationItemList[_itemID].assessor = _assessor;
    donationItemList[_itemID].itemState = uint8(ItemState.AssignedToAssessor);
    assessors2Items[_assessor].push(_itemID);
  }

  function itemUpForAuction(uint32 _itemID, address _assessor) public {
    require(_itemID < donationID);
    require(actorList[_assessor].isRegistered);
    require(donationItemList[_itemID].assessor == _assessor);
    donationItemList[_itemID].itemState = uint8(ItemState.ListedForAuction);
  }

  // Buyer doesn't need to be registered with GiveKindlySystem because they aren't relevant to taxes
  // Buyer would be registered with the Auctioneer
  function logCompletedAuction(uint32 _itemID, address _assessor, uint32 _value) public {
    require(_itemID < donationID);
    require(actorList[_assessor].isRegistered);
    require(donationItemList[_itemID].assessor == _assessor);
    donationItemList[_itemID].itemState = uint8(ItemState.Sold);
    donationItemList[_itemID].assessedValue = _value;
  }



  //==================================================
  // These functions go into Donor contract later.
  // Currently in 1 contract because of Ganache issue.
  //==================================================
  function donor_registerDonor(string _name, string _email, string _physAddr) public {
    registerActor(msg.sender, uint8(GiveKindlySystem.ActorRole.Donor), _name, _email, _physAddr);
  }

  function donor_donate(address _charity, uint8 _itemType, string _description) public {
    // Currently we don't do anything with the return value
    logDonation(msg.sender, _charity, _itemType, _description);
  }

  // TODO: Add function to query the donations for the calling donor



  //==================================================
  // These functions go into Charity contract later.
  // Currently in 1 contract because of Ganache issue.
  //==================================================

  // TODO: In future, a charity might have multiple staff working for it
  function charity_registerCharity(string _name, string _email, string _physAddr) public {
    registerActor(msg.sender, uint8(GiveKindlySystem.ActorRole.Charity), _name, _email, _physAddr);
  }

  function charity_assignAssessor(uint32 _itemID, address _assessor) public {
    assignAssessor(_itemID, msg.sender, _assessor);
  }

  // TODO: Add function to query the donations for the calling charity


  //==================================================
  // These functions go into CRA contract later.
  // Currently in 1 contract because of Ganache issue.
  //==================================================

  // TODO: In future, CRA might have multiple staff working for it
  // TODO: For security, want to limit who can register as CRA. Need whitelist.
  function cra_registerCRA(string _name, string _email, string _physAddr) public {
    registerActor(msg.sender, uint8(GiveKindlySystem.ActorRole.CRA), _name, _email, _physAddr);
  }

  // TODO: Add functions to query anything CRA would be interested in


    //==================================================
    // These functions go into Auctioneer contract later.
    // Currently in 1 contract because of Ganache issue.
    //==================================================

    // TODO: In future, an auction house might have multiple staff working for it
    // TODO: Approved auction houses should be whitelisted, so not anyone can auction
    function auctioneer_registerAuctioneer(string _name, string _email, string _physAddr) public {
      registerActor(msg.sender, uint8(GiveKindlySystem.ActorRole.Auctioneer), _name, _email, _physAddr);
    }

    function auctioneer_auctionItem(uint32 _itemID) public {
      // TODO: Add auction logic. Deploy an auction contract for each item? Factory pattern?
      itemUpForAuction(_itemID, msg.sender);
    }

    // TODO: Auction logic needs to call
    // gks.logCompletedAuction(uint32 _itemID, msg.sender, _buyer, _value)

    // TODO: Add function to query the donations for the calling auctioneer
}
