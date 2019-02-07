var TuneTrader = artifacts.require('TuneTrader')
var SongERC20 = artifacts.require('SongERC20')
var SongCrowdsale = artifacts.require('SongCrowdsale')
// var TXTSale = artifacts.require("TXTCrowdsale");
require('babel-polyfill')
var BigNumber = require('bignumber.js')

var chai = require('chai')
var chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
chai.use(require('chai-bignumber')())
chai.use(require('chai-bignumber')(BigNumber))

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
var mySong = null
var songToken = null
var saleInstance = null
var bonuses = [1, 10, 2, 20, 3, 30, 4, 40]
var myBalance = 0
var decimals = 18
var rate = 1

// Accounts definition
// accounts[9] - founder wallet account in token contract
// accounts[1] - crowdsale wallet account
// accounts[0] - pool account & crowdsale & token contract original creators.
// accounts[2] - test token buyer

contract('Test TuneTrader Contract Bonuses', async accounts => {
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
  // function AddSong(string _name, string _author,string _genre, uint8 _entryType,string _website,uint _totalSupply,string _symbol,string _description,string _soundcloud,bool _ico,uint _id)

  // function AddICO(address _wallet,uint256 _teamTokens,uint256[] constraints, uint256 _price, uint256 _durationDays, uint _presaleduration,uint8[] _bonuses,uint256 assignedTokens) public

  it('03. Adding ICO with added song for ICO should be fulfiled', async () => {
    var constraints = [0, 0, 0, 0, 0]
    await TuneTraderContract.addICO(saleWallet, teamTokens, constraints, rate, 10, 10, bonuses, assignTokens, {
      gasPrice: 1
    })
    let mySongs = await TuneTraderContract.getMySongs.call()
    songToken = await SongERC20.at(mySongs[0])
    let myICO = await TuneTraderContract.getICO.call(mySongs[0])
    saleInstance = await SongCrowdsale.at(myICO)
    return expect(myICO).to.be.not.equal(0)
  })

  it('04. Should get 1 Tokens and Mini Tokens 1 for 1 ETH ', async () => {
    console.log(Math.pow(10, 18))
    let result = await saleInstance.getTokensForWei.call(Math.pow(10, 18).toString(), 0, 1000)
    return result[2].eq(Math.pow(10, 18)) && result[0].eq('1') && result[1].eq('1')
  })

  it('05. Should get 0 Tokens and Mini Tokens 0 for 1 ETH - 1 Wei ', async () => {
    let weiAmount = BigNumber(1).shiftedBy(18)
    weiAmount = weiAmount.minus(1)
    let result2 = await saleInstance.getTokensForWei.call(weiAmount.toString(), 0, 1)
    return result2[2].eq('0') && result2[0].eq('0') && result2[1].eq('0')
  })

  it('06. Price 10 Tokens/ETH, Decimals: 1, Wei amount: 0.019 ETH. Expect 0.1 Token and 0.01 ETH  ', async () => {
    let weiAmount = new BigNumber(0.019).shiftedBy(18)
    let result2 = await saleInstance.getTokensForWei.call(weiAmount.toString(), 1, 10)
    let resultWei = new BigNumber(result2[2])
    let expected = new BigNumber(0.01).shiftedBy(18)
    console.log('W:', weiAmount.toString())
    console.log('R:', resultWei.toString())
    console.log('E:', expected.toString())
    console.log('B:', result2[3].toString())
    console.log('Mini token: ', result2[0].toString())
    console.log('Token: ', result2[1].toString())
    return expect(resultWei.toString()).to.be.equal(expected.toString())
  })

  it('07. Price 100 Tokens/ETH, Decimals: 2, Wei amount: 0.5001 ETH. Expect 50 Token and 0.501 ETH cost and 5001 Mini tokens and 0 wei to return    ', async () => {
    let weiAmount = new BigNumber(0.5001).shiftedBy(18)
    let result2 = await saleInstance.getTokensForWei.call(weiAmount.toString(), 2, 100)
    let resultWei = new BigNumber(result2[2])
    let expected = new BigNumber(0.01).shiftedBy(18)
    console.log('W:', weiAmount.toString())
    console.log('R:', resultWei.toString())
    console.log('E:', expected.toString())
    console.log('B:', result2[3].toString())
    console.log('Mini token: ', result2[0].toString())
    console.log('Token: ', result2[1].toString())
    return expect(result2[0].toString()).to.be.equal('5001')
  })

  it('08. Price 100 Tokens/ETH, Decimals: *1*, Wei amount: 0.5001 ETH. Expect 50 Token and 0.5000 ETH cost and 500 Mini tokens and 0.0001 ETH to return    ', async () => {
    let weiAmount = new BigNumber(0.5001).shiftedBy(18)
    let result2 = await saleInstance.getTokensForWei.call(weiAmount.toString(), 1, 100)
    let resultWei = new BigNumber(result2[2])
    let expected = new BigNumber(0.01).shiftedBy(18)
    console.log('W:', weiAmount.toString())
    console.log('R:', resultWei.toString())
    console.log('E:', expected.toString())
    console.log('B:', result2[3].toString())
    console.log('Mini token: ', result2[0].toString())
    console.log('Token: ', result2[1].toString())
    expect(result2[0].toString()).to.be.equal('500')
    expect(result2[1].toString()).to.be.equal('50')
    expect(result2[2].toString()).to.be.equal(
      BigNumber(0.5)
        .shiftedBy(18)
        .toString()
    )
    expect(result2[3].toString()).to.be.equal(
      BigNumber(0.0001)
        .shiftedBy(18)
        .toString()
    )
    // return (expect(result2[0].toString()).to.be.equal('501') && expect(result2[3].toString()).to.be.equal(BigNumber(0.0002).shiftedBy(18).toString()))
  })

  it('09. Price 2500 Tokens/ETH, Decimals: *0*, Wei amount: 0.001 ETH. Expect 2 Tokens and 0.0008 ETH cost and 2 Mini tokens and 0.0002 ETH to return    ', async () => {
    let weiAmount = new BigNumber(0.001).shiftedBy(18)
    let result2 = await saleInstance.getTokensForWei.call(weiAmount.toString(), 0, 2500)
    let resultWei = new BigNumber(result2[2])
    let expected = new BigNumber(0.0008).shiftedBy(18)
    console.log('W:', weiAmount.toString())
    console.log('R:', resultWei.toString())
    console.log('E:', expected.toString())
    console.log('B:', result2[3].toString())
    console.log('Mini token: ', result2[0].toString())
    console.log('Token: ', result2[1].toString())
    expect(result2[0].toString()).to.be.equal('2')
    expect(result2[1].toString()).to.be.equal('2')
    expect(result2[2].toString()).to.be.equal(
      BigNumber(0.0008)
        .shiftedBy(18)
        .toString()
    )
    expect(result2[3].toString()).to.be.equal(
      BigNumber(0.0002)
        .shiftedBy(18)
        .toString()
    )
    // return (expect(result2[0].toString()).to.be.equal('501') && expect(result2[3].toString()).to.be.equal(BigNumber(0.0002).shiftedBy(18).toString()))
  })

  it('10. Price 1 Token/ETH, Decimals: 18, Wei amount: 0.00001 ETH. Expect 0.00001 Tokens and 0.00001 ETH cost and 0.00001 shifted by 18 Mini tokens and 0 ETH to return    ', async () => {
    let weiAmount = new BigNumber(0.00001).shiftedBy(18)
    let result2 = await saleInstance.getTokensForWei.call(weiAmount.toString(), 18, 1)
    let resultWei = new BigNumber(result2[2])
    let expected = new BigNumber(0.00001).shiftedBy(18)
    console.log('W:', weiAmount.toString())
    console.log('R:', resultWei.toString())
    console.log('E:', expected.toString())
    console.log('B:', result2[3].toString())
    console.log('Mini token: ', result2[0].toString())
    console.log('Token: ', result2[1].toString())
    expect(result2[0].toString()).to.be.equal(
      BigNumber('0.00001')
        .shiftedBy(18)
        .toString()
    )
    expect(result2[1].toString()).to.be.equal('0')
    expect(result2[2].toString()).to.be.equal(
      BigNumber(0.00001)
        .shiftedBy(18)
        .toString()
    )
    expect(result2[3].toString()).to.be.equal(
      BigNumber(0)
        .shiftedBy(18)
        .toString()
    )
  })
})
