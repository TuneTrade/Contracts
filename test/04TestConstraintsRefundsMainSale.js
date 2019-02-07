var TuneTrader = artifacts.require('TuneTrader')
var SongERC20 = artifacts.require('SongERC20')
var SongCrowdsale = artifacts.require('SongCrowdsale')
// var TXTSale = artifacts.require("TXTCrowdsale");
require('babel-polyfill')

var chai = require('chai')
var BigNumber = require('bignumber.js')
var chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
expect = chai.expect

var TuneTraderContract = 0
// var TXTSaleContract = 0;
// var TXTSaleContract2 = 0;
// var totalSupply = 0;
var owner = 0
var saleWallet = 0
var poolAddress = 0
var foundersWallet = 0
var testBuyer = 0
var testBuyer2 = 0
var balance = 0
var assignTokens = 40000
var teamTokens = 1000
var rate = 500
var decimals = 16
var mySong = null
var songToken = null
var saleInstance = null
var bonuses = [1, 10, 2, 20, 3, 30, 4, 40]
var constraints = [0, 20, 100, 40000, 500]
// uint _minpresale = constraints[0];
// uint _minMainSaleETH = constraints[1];
// uint _maxEth = constraints[2];
// uint _maxCap = constraints[3];
// uint _minCap = constraints[4];

var myBalance = 0

// Accounts definition
// accounts[9] - founder wallet account in token contract
// accounts[1] - crowdsale wallet account
// accounts[0] - pool account & crowdsale & token contract original creators.
// accounts[2] - test token buyer

contract('Test TuneTrader Contract for Main Sale min ETH sale and refund. ', async accounts => {
  poolAddress = accounts[0]
  saleWallet = accounts[1]
  foundersWallet = accounts[9]
  testBuyer = accounts[2]
  testBuyer2 = accounts[3]

  it('01. Catch an instance of TuneTrader Smart Contract', async () => {
    TuneTraderContract = await TuneTrader.deployed()
    console.log(' ')
    console.log('    ***********************************************************')
    console.log('    TuneTrader Contract:    '.blue, TuneTraderContract.address)
    console.log('    ***********************************************************')
    console.log(' ')
  })

  it('02. Should be able to add new Song with ICO', function () {
    return expect(
      TuneTraderContract.addSong(
        'Song Name',
        'Author',
        'Genre',
        1,
        'website.com',
        assignTokens,
        'SYM',
        'Description',
        'soundcloud.com',
        'youtube',
        true,
        decimals,
        1,
        { gasPrice: 1 }
      )
    ).to.be.eventually.fulfilled
  })

  it('03. Adding ICO with added song for ICO should be fulfiled', async () => {
    await TuneTraderContract.addICO(saleWallet, teamTokens, constraints, rate, 10, 10, bonuses, assignTokens, {
      gasPrice: 1
    })
    let mySongs = await TuneTraderContract.getMySongs.call()
    songToken = await SongERC20.at(mySongs[0])
    let myICO = await TuneTraderContract.getICO.call(mySongs[0])
    saleInstance = await SongCrowdsale.at(myICO)
    expect(myICO).to.be.not.equal(0)
  })

  it('04. Should be possible to buy tokens for second bonus period with 30% bonus for the last second of this period', async () => {
    await saleInstance.setTestNow(15 * 24 * 3600)
    await saleInstance.sendTransaction({
      gas: 914366353,
      gasPrice: 1,
      value: 10,
      from: accounts[5]
    })
    myBalance = parseInt(await songToken.balanceOf.call(accounts[5]))
    expect(parseInt(myBalance)).to.be.equal(1.3 * 10 * rate)
  })

  it('05. Should be possible to buy tokens for third bonus period with 40% bonus for the first second of this period', async () => {
    await saleInstance.setTestNow(15 * 24 * 3600 + 1)
    await saleInstance.sendTransaction({
      gas: 914366353,
      gasPrice: 1,
      value: 1,
      from: accounts[5]
    })
    let oldBalance = myBalance
    myBalance = parseInt(await songToken.balanceOf.call(accounts[5]))
    expect(parseInt(myBalance)).to.be.equal(oldBalance + 1.4 * 1 * rate)
  })

  it('06. Contract should NOT be in refund state before finish Main Sale. Only 11 wei was collected for min of 20.', async () => {
    let state = await saleInstance.getCampaignState.call()
    return expect(state).to.be.not.equal('Refund')
  })

  it('07. Contract should  be in refund state after finish Main Sale. Only 11 wei was collected for min of 20.', async () => {
    await saleInstance.setTestNow(20 * 24 * 3600 + 1)
    let state = await saleInstance.getCampaignState.call()
    return expect(state).to.be.equal('Refund')
  })

  it('08. Should be possible to buy mor tokens to fulfill minimum Cap. ', async () => {
    await saleInstance.setTestNow(15 * 24 * 3600 + 1)
    await saleInstance.sendTransaction({
      gas: 914366353,
      gasPrice: 1,
      value: 10,
      from: accounts[5]
    })
    let oldBalance = myBalance
    myBalance = parseInt(await songToken.balanceOf.call(accounts[5]))
    expect(parseInt(myBalance)).to.be.equal(oldBalance + 1.4 * 10 * rate)
  })

  it('09. Contract should  be in Ended state after finish Main Sale. 21 wei was collected..', async () => {
    await saleInstance.setTestNow(20 * 24 * 3600 + 1)
    let state = await saleInstance.getCampaignState.call()
    return expect(state).to.be.equal('Ended')
  })

  it('10. Owner should be able to receive all raised ETH (21 Wei)', async () => {
    await saleInstance.setTestNow(20 * 24 * 3600 + 1)
    let initBalance = await web3.eth.getBalance(saleWallet)
    initBalance = BigNumber(initBalance)
    let tx = await saleInstance.withdrawFunds({
      from: saleWallet,
      gasPrice: 1
    })
    let curBalance = await web3.eth.getBalance(saleWallet)
    curBalance = BigNumber(curBalance)
    return expect(initBalance.toString()).to.be.equal(
      curBalance
        .plus(tx.receipt.gasUsed)
        .minus(21)
        .toString()
    )
  })

  it('11.Contract should be in Closed state after funds were withdrawn by Sale wallet account.', async () => {
    await saleInstance.setTestNow(20 * 24 * 3600 + 1)
    let state = await saleInstance.getCampaignState.call()
    return expect(state).to.be.equal('Closed')
  })
})
