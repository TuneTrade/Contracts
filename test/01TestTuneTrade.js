var TuneTrader = artifacts.require('TuneTrader')
var SongERC20 = artifacts.require('SongERC20')
var SongCrowdsale = artifacts.require('SongCrowdsale')
var ContractStorage = artifacts.require('ContractStorage')

// var TXTSale = artifacts.require("TXTCrowdsale");
require('babel-polyfill')

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
var mySong = null
var songToken = null
var saleInstance = null
var decimals = 0
// Accounts definition
// accounts[9] - founder wallet account in token contract
// accounts[1] - crowdsale wallet account
// accounts[0] - pool account & crowdsale & token contract original creators.
// accounts[2] - test token buyer

contract('Test TuneTrader Contract General functionality. Song and ICO creation. Simple sale.', async accounts => {
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

  it('02. Should be able to add new Song without ICO', async () => {
    return expect(
      TuneTraderContract.AddSong(
        'TEST',
        'TEST',
        'TEST',
        '1',
        'TEST',
        '11111',
        'SYM',
        'DESC',
        'suondcloud',
        'youtube',
        false,
        decimals,
        '1'
      )
    ).to.be.eventually.fulfilled
  })

  it('03. Adding ICO without adding Song first should fail', async () => {
    var constraints = [0, 0, 0, 0, 0]
    var bonuses = [0, 0, 0, 0, 0, 0, 0, 0]
    return expect(TuneTraderContract.addICO(saleWallet, 100, constraints, 100, 1, 1, bonuses, 100)).to.be.eventually
      .rejected
  })

  it('04. Should be able to add new Song with ICO', function () {
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
        'youtube',
        true,
        decimals,
        1
      )
    ).to.be.eventually.fulfilled
  })
  // function AddSong(string _name, string _author,string _genre, uint8 _entryType,string _website,uint _totalSupply,string _symbol,string _description,string _soundcloud,bool _ico,uint _id)

  // function addICO(address _wallet,uint256 _teamTokens,uint256[] constraints, uint256 _price, uint256 _durationDays, uint _presaleduration,uint8[] _bonuses,uint256 assignedTokens) public

  it('05. Adding ICO with added song for ICO should be fulfiled', async () => {
    var constraints = [0, 0, 0, 0, 0]
    var bonuses = [0, 0, 0, 0, 0, 0, 0, 0]

    await TuneTraderContract.addICO(saleWallet, teamTokens, constraints, rate, 10, 10, bonuses, assignTokens)
    let mySongs = await TuneTraderContract.getMySongs.call()
    console.log(mySongs)
    songToken = await SongERC20.at(mySongs[1])
    let myICO = await TuneTraderContract.getICO.call(mySongs[1])
    console.log(myICO)
    saleInstance = await SongCrowdsale.at(myICO)
    // console.log(saleInstance)
    await expect(
      saleInstance.sendTransaction({
        gas: 914366353,
        gasPrice: 1,
        value: 1,
        from: accounts[5]
      })
    ).to.be.eventually.fulfilled
  })

  it('06. User should have two songs in TuneTrader contract ', async () => {
    let songs = await TuneTraderContract.getMySongs.call()
    await expect(songs.length).to.be.equal(2)
  })

  it(
    '07. ICO Balanace should be ' +
      parseInt(assignTokens - rate) +
      '. ' +
      assignTokens +
      ' assigned - ' +
      rate +
      ' sold.',
    async () => {
      let balance = await songToken.balanceOf.call(saleInstance.address)
      await expect(parseInt(balance)).to.be.equal(assignTokens - rate)
    }
  )

  it('08. Accounts[5] balance should be ' + rate + ' tokens', async () => {
    let balance = await songToken.balanceOf.call(accounts[5])
    await expect(parseInt(balance)).to.be.equal(rate)
  })

  it('09. It should be not possible to buy tokens which are part of teamTokens', async () => {
    let weiAmount = parseInt((assignTokens - teamTokens - rate) / rate)
    await expect(
      saleInstance.sendTransaction({
        gas: 914366353,
        gasPrice: 1,
        value: weiAmount + 1,
        from: accounts[5]
      })
    ).to.be.eventually.rejected
  })
})
