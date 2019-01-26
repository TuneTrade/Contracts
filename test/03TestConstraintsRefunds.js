var TuneTrader = artifacts.require('TuneTrader')
var SongERC20 = artifacts.require('SongERC20')
var SongCrowdsale = artifacts.require('SongCrowdsale')
// var TXTSale = artifacts.require("TXTCrowdsale");
require('babel-polyfill')
var BigNumber = require('bignumber.js')
var chai = require('chai')
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
var assignTokens = 30000
var teamTokens = 1000
var rate = 500
var decimals = 18
var mySong = null
var songToken = null
var saleInstance = null
var bonuses = [1, 10, 2, 20, 3, 30, 4, 40]
var constraints = [10, 20, 100, 5000, 500]
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

contract('Test TuneTrader Contract for maxCap constrain and minpresale constrain and refund. ', async accounts => {
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
      TuneTraderContract.AddSong(
        'Song Name',
        'Author',
        'Genre',
        1,
        'website.com',
        assignTokens,
        'SYM',
        'Description',
        'soundcloud.com',
        'youtube.com',
        true,
        decimals,
        1,
        { gasPrice: 1 }
      )
    ).to.be.eventually.fulfilled
  })
  // function AddSong(string _name, string _author,string _genre, uint8 _entryType,string _website,uint _totalSupply,string _symbol,string _description,string _soundcloud,bool _ico,uint _id)

  // function AddICO(address _wallet,uint256 _teamTokens,uint256[] constraints, uint256 _price, uint256 _durationDays, uint _presaleduration,uint8[] _bonuses,uint256 assignedTokens) public

  it('03. Adding ICO with added song for ICO should be fulfiled', async () => {
    await TuneTraderContract.AddICO(saleWallet, teamTokens, constraints, rate, 10, 10, bonuses, assignTokens, {
      gasPrice: 1
    })
    let mySongs = await TuneTraderContract.GetMySongs.call()
    songToken = await SongERC20.at(mySongs[0])
    let myICO = await TuneTraderContract.GetICO.call(mySongs[0])
    saleInstance = await SongCrowdsale.at(myICO)
    expect(myICO).to.be.not.equal(0)
  })

  it('04. Should be possible to buy tokens first second of presale.10% bonus applies.', async () => {
    await saleInstance.SetTestNow(0)
    await saleInstance.sendTransaction({
      gas: 914366353,
      gasPrice: 1,
      value: 8,
      from: accounts[5]
    })
    myBalance = parseInt(await songToken.balanceOf.call(accounts[5]))
    expect(parseInt(myBalance)).to.be.equal(1.1 * 8 * rate)
  })

  it('05. Should not be possible to buy tokens exceeding maxCap', function () {
    return expect(
      saleInstance.sendTransaction({
        gas: 914366353,
        gasPrice: 1,
        value: 2,
        from: accounts[5]
      })
    ).to.be.eventually.rejected
  })

  it("06. Sale should be in Refund state after presale ends and minimum presale condition wasn't met", async () => {
    await saleInstance.SetTestNow(10 * 24 * 3600 + 1)
    let state = await saleInstance.CampaignState.call({ gasPrice: 1 })
    expect(state).to.be.equal('Refund')
  })

  it('07.It should be not possible to buy tokens in refund state.First transaction should be fulfilled. Account balance should be only subtracted by transaction cost.', async () => {
    let initBalance = await web3.eth.getBalance(accounts[5])
    let tx = await saleInstance.sendTransaction({
      gas: 914366353,
      gasPrice: 1,
      value: 5000,
      from: accounts[5]
    })
    let curBalance = await web3.eth.getBalance(accounts[5])
    initBalance = BigNumber(initBalance)
    await expect(curBalance.toString()).to.be.equal(initBalance.minus(tx.receipt.gasUsed).toString())
  })

  it('08.It should be not possible to buy tokens in refund state.Second transaction should be rejected.', async () => {
    await expect(
      saleInstance.sendTransaction({
        gas: 914366353,
        gasPrice: 1,
        value: 1,
        from: accounts[5]
      })
    ).to.be.eventually.rejected
  })

  it("09. Since two buying transaction failed. Token balance shouldn't change. ", async () => {
    let curBalance = parseInt(await songToken.balanceOf.call(accounts[5]))
    await expect(parseInt(curBalance)).to.be.equal(myBalance)
  })

  it('10. It should be possible to ask for refund.This should return 8 wei', async () => {
    let initBalance = await web3.eth.getBalance(accounts[5])
    let tx = await saleInstance.refund({ from: accounts[5], gasPrice: 1 })
    let curBalance = await web3.eth.getBalance(accounts[5])
    initBalance = BigNumber(initBalance)
    await expect(curBalance.toString()).to.be.equal(
      initBalance
        .plus(8)
        .minus(tx.receipt.gasUsed)
        .toString()
    )
  })
})
