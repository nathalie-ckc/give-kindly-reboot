var GiveKindlySystem = artifacts.require("./GiveKindlySystem.sol");

contract('GiveKindlySystem', function(accounts) {

  const owner = accounts[0]
  const alice = accounts[1];
  const bigsisters = accounts[2];
  const canauction = accounts[3];
  const bidder1 = accounts[4];
  const bidder2 = accounts[5];
  const bidder3 = accounts[6];

  it("donate 2 items, assign them to auctioneer, auction & charity takes $", async () => {
    const gks = await GiveKindlySystem.deployed();

    await gks.donor_registerDonor("Alice", "a@gmail", "111 Main", {from: alice});
    const num1 = await gks.numActorsRegistered().then(result => result.toNumber());
    assert.equal(num1, 1, 'Alice did not get registered');

    await gks.charity_registerCharity("BigSisters", "b@hotmail", "123 Sesame", {from: bigsisters});
    const num2 = await gks.numActorsRegistered().then(result => result.toNumber());
    assert.equal(num2, 2, 'BigSisters did not get registered');

    await gks.auctioneer_registerAuctioneer("CanAuction", "c@aol", "10 Park", {from: canauction});
    const num3 = await gks.numActorsRegistered().then(result => result.toNumber());
    assert.equal(num3, 3, 'CanAuction did not get registered');

    await gks.donor_donate(bigsisters, 0, "ToyotaSupra", {from: alice});
    await gks.donor_donate(bigsisters, 2, "MinnieWinnie", {from: alice});
    const dc = await gks.getDonationCount().then(result => result.toNumber());
    assert.equal(dc, 2, "Donation unsuccessful");

    await gks.charity_assignAssessor(0, canauction, {from: bigsisters});
    await gks.charity_assignAssessor(1, canauction, {from: bigsisters});
    const donID = await gks.assessors2Items(canauction, 1).then(result => result.toNumber());
    assert.equal(donID, 1, "Auctioneer assignment unsuccessful");

    await gks.auctioneer_auctionItem(1, {from: canauction});
    const aucItem = await gks.itemBeingAuctioned().then(result => result.toNumber());
    assert.equal(aucItem, 1, "Item 1 was NOT successfully put up for auction");

    await gks.auctioneer_newBid({from:bidder1, value:10000000});
    const hb1 = await gks.highestBid().then(result => result.toNumber());
    assert.equal(hb1, 10000000, "Bid1 failed");

    await gks.auctioneer_newBid({from:bidder2, value:50000000});
    const hb2 = await gks.highestBid().then(result => result.toNumber());
    assert.equal(hb2, 50000000, "Bid2 failed");

    await gks.auctioneer_newBid({from:bidder3, value:30000000});
    const hb3 = await gks.highestBid().then(result => result.toNumber());
    assert.equal(hb3, 50000000, "Bid3 should not have won");

    await gks.auctioneer_endAuction({from: canauction});
    const val = await gks.getValueForItem(1).then(result => result.toNumber());
    assert.equal(val, 50000000, "Item 1 was NOT successfully sold in auction");

    const charity_b4 = await gks.auctioneer_getMyCharityBalance({from: bigsisters}).then(
      result => result.toNumber());
    await gks.auctioneer_charityWithdraw({from:bigsisters});
    const charity_after = await gks.auctioneer_getMyCharityBalance({from: bigsisters}).then(
      result => result.toNumber());
    assert.equal((charity_b4 - charity_after), 50000000, "Charity failed to withdraw funds");

    const b1_b4 = await gks.auctioneer_getMyBidderBalance({from: bidder1}).then(
      result => result.toNumber());
    await gks.auctioneer_returnLosingBid({from:bidder1});
    const b1_after = await gks.auctioneer_getMyBidderBalance({from: bidder1}).then(
      result => result.toNumber());
    assert.equal((b1_b4 - b1_after), 10000000, "Bidder1 failed to withdraw funds");
  });
  /*


    await bank.enroll({from: alice});

    const aliceEnrolled = await bank.enrolled(alice, {from: alice});
    assert.equal(aliceEnrolled, true, 'enroll balance is incorrect, check balance method or constructor');

    const ownerEnrolled = await bank.enrolled(owner, {from: owner});
    assert.equal(ownerEnrolled, false, 'only enrolled users should be marked enrolled');
  });

  it("should deposit correct amount", async () => {
    const bank = await SimpleBank.deployed();

    await bank.enroll({from: bob});

    await bank.deposit({from: alice, value: deposit});
    const balance = await bank.balance({from: alice});
    assert.equal(deposit.toString(), balance, 'deposit amount incorrect, check deposit method');

    const expectedEventResult = {accountAddress: alice, amount: deposit};

    const LogDepositMade = await bank.LogDepositMade();
    const log = await new Promise(function(resolve, reject) {
        LogDepositMade.watch(function(error, log){ resolve(log);});
    });

    const logAccountAddress = log.args.accountAddress;
    const logDepositAmount = log.args.amount.toNumber();

    assert.equal(expectedEventResult.accountAddress, logAccountAddress, "LogDepositMade event accountAddress property not emitted, check deposit method");
    assert.equal(expectedEventResult.amount, logDepositAmount, "LogDepositMade event amount property not emitted, check deposit method");
  });

  it("should withdraw correct amount", async () => {
    const bank = await SimpleBank.deployed();
    const initialAmount = 0;

    await bank.withdraw(deposit, {from: alice});
    const balance = await bank.balance({from: alice});

    assert.equal(balance.toString(), initialAmount.toString(), 'balance incorrect after withdrawal, check withdraw method');

    const LogWithdrawal = await bank.LogWithdrawal();
    const log = await new Promise(function(resolve, reject) {
      LogWithdrawal.watch(function(error, log){ resolve(log);});
    });

    const accountAddress = log.args.accountAddress;
    const newBalance = log.args.newBalance.toNumber();
    const withdrawAmount = log.args.withdrawAmount.toNumber();

    const expectedEventResult = {accountAddress: alice, newBalance: initialAmount, withdrawAmount: deposit};


    assert.equal(expectedEventResult.accountAddress, accountAddress, "LogWithdrawal event accountAddress property not emitted, check deposit method");
    assert.equal(expectedEventResult.newBalance, newBalance, "LogWithdrawal event newBalance property not emitted, check deposit method");
    assert.equal(expectedEventResult.withdrawAmount, withdrawAmount, "LogWithdrawal event withdrawalAmount property not emitted, check deposit method");

  });
  */
});
