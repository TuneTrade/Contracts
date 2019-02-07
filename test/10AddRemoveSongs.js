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

contract('Test Adding and Removing Songs with and without ICO', async accounts => {
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

  it('02. Should be able to add 2 new Songs without ICO', async () => {
    await expect(
      TuneTraderContract.addSong(
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
        '1',
        { from: accounts[2] }
      )
    ).to.be.eventually.fulfilled

    await expect(
      TuneTraderContract.addSong(
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
        '1',
        { from: accounts[1] }
      )
    ).to.be.eventually.fulfilled
  })

  it('03. Should be able to add 1 new Song with ICO', async () => {
    var constraints = [0, 0, 0, 0, 0]
    var bonuses = [0, 0, 0, 0, 0, 0, 0, 0]

    await expect(
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
        { from: accounts[1] }
      )
    ).to.be.eventually.fulfilled

    await TuneTraderContract.addICO(saleWallet, teamTokens, constraints, rate, 10, 10, bonuses, assignTokens, {
      from: accounts[1]
    })
    let mySongs = await TuneTraderContract.getMySongs.call()
    console.log(mySongs)
  })

  it('04. There should be three songs in Contract and two songs for accounts[1] ', async () => {
    let songs = await TuneTraderContract.getSongs.call()
    await expect(songs.length).to.be.equal(3)

    let songs1 = await TuneTraderContract.getMySongs.call({ from: accounts[1] })
    await expect(songs1.length).to.be.equal(2)
  })

  it('05. Should be able to remove second song. Third song should become second one. ', async () => {
    let songs = await TuneTraderContract.getSongs.call()
    console.log('Remove song:', songs[1])
    let res = await TuneTraderContract.getSongsLength.call(songs[1])
    console.log('MaxIndex:', res[0].toString())
    console.log('Index:', res[1].toString())
    console.log('Max Index Address:', res[2])
    await TuneTraderContract.removeSong(songs[1])
    let afterSongs = await TuneTraderContract.getSongs.call()
    console.log(afterSongs)
    await expect(afterSongs.length).to.be.equal(2)
    await expect(songs[0]).to.be.equal(afterSongs[0])
    await expect(songs[2]).to.be.equal(afterSongs[1])

    await expect(TuneTraderContract.removeSong(afterSongs[0], { from: accounts[1] })).to.be.eventually.rejected
    await expect(TuneTraderContract.removeSong(afterSongs[0], { from: accounts[2] })).to.be.eventually.fulfilled
    songs = await TuneTraderContract.getSongs.call()
    console.log(songs)
    res = await TuneTraderContract.getSongsLength.call(songs[0])
    console.log('MaxIndex:', res[0].toString())
    console.log('Index:', res[1].toString())
    console.log('Max Index Address:', res[2])
    await expect(TuneTraderContract.removeSong(songs[0], { from: accounts[0] })).to.be.eventually.fulfilled
    afterSongs = await TuneTraderContract.getSongs.call()
    console.log(afterSongs)
    await expect(afterSongs.length).to.be.equal(0)
  })
})