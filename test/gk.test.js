var GiveKindlySystem = artifacts.require("./GiveKindlySystem.sol");

contract('GiveKindlySystem', function(accounts) {

  const owner = accounts[0]
  const alice = accounts[1];
  const bigsisters = accounts[2];
  const canauction = accounts[3];

  it("donate 2 items and assign them to auctioneer", async () => {
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
