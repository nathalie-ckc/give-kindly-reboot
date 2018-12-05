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

  address public gksAdmin;

  //==================================================
  // State variables for auction
  // These would go into Auctioneer contract when split into multuiple contracts
  //==================================================
  uint32 public itemBeingAuctioned;
  address public highestBidder;
  uint32 public highestBid;

  // Bidders who lost can withdraw their bid
  mapping(address => uint32) public pendingReturns;

  // Charities can withdraw proceeds of auctioned donations
  mapping(address => uint32) public charityFunds;

  // Set to true at the start of the auction and false at the end
  bool public auctionActive;

  //==================================================
  // Events
  //==================================================
  // GiveKindlySystem contract
  event LogRegistrationOfActor(address indexed _actorAcct, uint8 indexed _role, string _name, string _emailAddr, string _physicalAddr);
  event LogNewDonation(address indexed _donor, address indexed _charity, uint8 _itemType, string _description, uint32 indexed _itemID);
  event LogAssignmentOfAssessor(uint32 indexed _itemID, address indexed _charity, address indexed _assessor);
  event LogItemUpForAuction(uint32 indexed _itemID, address indexed _assessor);
  event LogAuctionCompleted(uint32 indexed _itemID, address indexed _assessor, uint32 indexed _value);

  // Auctioneer contract, if it were a separate contract
  event AuctionEnded(uint32 indexed itemBeingAuctioned, address indexed charity, address indexed highestBidder, uint32 highestBid);
  event NotifyBiddersNewAuction(uint32 indexed _itemID, address indexed charity, uint8 indexed itemType, string description);
  event BidAccepted(uint32 indexed itemBeingAuctioned, address indexed highestBidder, uint32 highestBid);

  //==================================================
  // Modifiers
  //==================================================

  modifier onlyAdmin {
    require(msg.sender == gksAdmin);
    _;
  }

  //==================================================
  // Constructor
  //==================================================

  constructor() public {
    gksAdmin = msg.sender;
  }

  //==================================================
  // Don't make these functions internal because the intent is to have the role functions
  // live in separate contracts for each role. But I have merged all into 1 contract because
  // of the issue with Ganache having VM error when I call a function in another contract &
  // I don't want to restrict myself to testing on just Remix JavaScript VM or Rinkeby
  //==================================================

  function getDonationCount() public view returns (uint32) {
    return donationID;
  }

  function getCharityForItem(uint32 _itemID) public view  returns (address) {
    return donationItemList[_itemID].charity;
  }

  function getValueForItem(uint32 _itemID) public view returns (uint32) {
    return donationItemList[_itemID].assessedValue;
  }

  function getTypeForItem(uint32 _itemID) public view returns (uint8) {
    return donationItemList[_itemID].itemType;
  }

  function getDescrForItem(uint32 _itemID) public view returns (string) {
    return donationItemList[_itemID].description;
  }

  function registerActor(address _actorAcct, uint8 _role, string _name, string _email, string _physAddr) public {
    require(_actorAcct != 0x0);
    require(_role < numActorRoles);
    actorList[_actorAcct] = GKActor(_actorAcct, _role, true, _name, _email, _physAddr);
    numActorsRegistered++;
    emit LogRegistrationOfActor(_actorAcct, _role, _name, _email, _physAddr);
  }

  function newDonation(address _donor, address _charity, uint8 _itemType, string _descr) public returns (uint32) {
    require(actorList[_donor].isRegistered);
    require(actorList[_charity].isRegistered);
    require(_itemType < numItemTypes);
    uint32 retval = donationID;
    donationItemList.push(DonationItem(_donor, _charity, 0, 0, uint8(ItemState.AssignedToCharity), _itemType, _descr));
    donors2Items[_donor].push(donationID);
    charities2Items[_charity].push(donationID);
    emit LogNewDonation(_donor, _charity, _itemType, _descr, donationID);
    donationID++;
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
    emit LogAssignmentOfAssessor(_itemID, _charity, _assessor);
  }

  function itemUpForAuction(uint32 _itemID, address _assessor) public returns (bool){
    require(_itemID < donationID);
    require(actorList[_assessor].isRegistered);
    require(donationItemList[_itemID].assessor == _assessor);
    donationItemList[_itemID].itemState = uint8(ItemState.ListedForAuction);
    emit LogItemUpForAuction(_itemID, _assessor);
    return true;
  }

  // Bidder doesn't need to be registered with GiveKindlySystem because they aren't relevant to taxes
  // TODO: Bidder would be registered with the Auctioneer
  function auctionCompleted(uint32 _itemID, address _assessor, uint32 _value) public {
    require(_itemID < donationID);
    require(actorList[_assessor].isRegistered);
    require(donationItemList[_itemID].assessor == _assessor);
    donationItemList[_itemID].itemState = uint8(ItemState.Sold);
    donationItemList[_itemID].assessedValue = _value;
    emit LogAuctionCompleted(_itemID, _assessor, _value);
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
    newDonation(msg.sender, _charity, _itemType, _description);
  }


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


  //==================================================
  // These functions go into CRA contract later.
  // Currently in 1 contract because of Ganache issue.
  //==================================================

  // TODO: In future, CRA might have multiple staff working for it
  // TODO: For security, want to limit who can register as CRA. Need whitelist.
  function cra_registerCRA(string _name, string _email, string _physAddr) public {
    registerActor(msg.sender, uint8(GiveKindlySystem.ActorRole.CRA), _name, _email, _physAddr);
  }


    //==================================================
    // These functions go into Auctioneer contract later.
    // Currently in 1 contract because of Ganache issue.
    //==================================================

    // TODO: In future, an auction house might have multiple staff working for it
    // TODO: Approved auction houses should be whitelisted, so not anyone can auction
    function auctioneer_registerAuctioneer(string _name, string _email, string _physAddr) public {
      registerActor(msg.sender, uint8(GiveKindlySystem.ActorRole.Auctioneer), _name, _email, _physAddr);
    }

    // HACK: Since ganache doesn't let me call functions in other contracts,
    // only have 1 item up for auction at a time
    // TODO: When separate contracts, deploy an auction contract for each item? Factory pattern?
    function auctioneer_auctionItem(uint32 _itemID) public {
      address charity;
      uint8 itemType;
      string memory description;
      itemUpForAuction(_itemID, msg.sender);
      itemBeingAuctioned = _itemID;
      charity = getCharityForItem(_itemID);
      itemType = getTypeForItem(_itemID);
      description = getDescrForItem(_itemID);
      auctionActive = true;
      emit NotifyBiddersNewAuction(_itemID, charity, itemType, description);
    }

    function auctioneer_endAuction() public {
      // TODO: Put checks on auctioneer before de-activating the auction
      address charity = getCharityForItem(itemBeingAuctioned);
      auctionActive = false;
      auctionCompleted(itemBeingAuctioned, msg.sender, highestBid);
      charityFunds[charity] = highestBid;
      emit AuctionEnded(itemBeingAuctioned, charity, highestBidder, highestBid);
    }

    function auctioneer_newBid() public payable returns (bool){
      require (auctionActive);
      if (uint32(msg.value) <= highestBid) {
        return false;
      }
      if (highestBid != 0) {
        pendingReturns[highestBidder] = highestBid;
      }
      highestBidder = msg.sender;
      highestBid = uint32(msg.value);
      emit BidAccepted(itemBeingAuctioned, highestBidder, highestBid);
      return true;
    }

    /// Withdraw a bid that was overbid.
    function auctioneer_returnLosingBid() public returns (bool) {
      uint amount = uint(pendingReturns[msg.sender]);
      if (amount > 0) {
        pendingReturns[msg.sender] = 0;

        if (!msg.sender.send(amount)) {
          pendingReturns[msg.sender] = uint32(amount);
          return false;
        }
      }
      return true;
    }

    function auctioneer_charityWithdraw() public returns(bool){
      uint amount = uint(charityFunds[msg.sender]);
      if (amount > 0) {
        charityFunds[msg.sender] = 0;

        if (!msg.sender.send(amount)) {
          charityFunds[msg.sender] = uint32(amount);
          return false;
        }
      }
      return true;
    }
}
