var TuneTrader = artifacts.require('TuneTrader')
var SongERC20 = artifacts.require('SongERC20')
var SongCrowdsale = artifacts.require('SongCrowdsale')
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
var decimals = 18
var mySong = null
var songToken = null
var saleInstance = null
var bonuses = [1, 10, 2, 20, 3, 30, 4, 40]
var myBalance = 0

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
        1,
        { gasPrice: 1 }
      )
    ).to.be.eventually.fulfilled
  })
  // function AddSong(string _name, string _author,string _genre, uint8 _entryType,string _website,uint _totalSupply,string _symbol,string _description,string _soundcloud,bool _ico,uint _id)

  // function AddICO(address _wallet,uint256 _teamTokens,uint256[] constraints, uint256 _price, uint256 _durationDays, uint _presaleduration,uint8[] _bonuses,uint256 assignedTokens) public

  it('03. Adding ICO with added song for ICO should be fulfiled', async () => {
    var constraints = [0, 0, 0, 0, 0]
    await TuneTraderContract.AddICO(saleWallet, teamTokens, constraints, rate, 10, 10, bonuses, assignTokens, {
      gasPrice: 1
    })
    let mySongs = await TuneTraderContract.GetMySongs.call()
    songToken = await SongERC20.at(mySongs[0])
    let myICO = await TuneTraderContract.GetICO.call(mySongs[0])
    saleInstance = await SongCrowdsale.at(myICO)
    expect(myICO).to.be.not.equal(0)
  })

  it('04. Should be possible to buy tokens from sale contract at the last second of Sale. No bonus.', async () => {
    await saleInstance.SetTestNow(20 * 24 * 3600)
    await saleInstance.sendTransaction({
      gas: 914366353,
      gasPrice: 1,
      value: 1,
      from: accounts[5]
    })
    myBalance = parseInt(await songToken.balanceOf.call(accounts[5]))
    expect(parseInt(myBalance)).to.be.equal(rate)
  })

  it('05. Should be possible to get presale Bonus at the first second of presale.', async () => {
    // var bonuses = [1,10,2,20,3,30,4,40]

    await saleInstance.SetTestNow(0)
    await saleInstance.sendTransaction({
      gas: 914366353,
      gasPrice: 1,
      value: 1,
      from: accounts[5]
    })
    let oldBalance = myBalance
    myBalance = parseInt(await songToken.balanceOf.call(accounts[5]))
    expect(parseInt(myBalance)).to.be.equal(1.1 * rate + oldBalance)
  })

  it('06. Should be possible to get presale Bonus at the last second of presale bonus.', async () => {
    // var bonuses = [1,10,2,20,3,30,4,40]
    await saleInstance.SetTestNow(1 * 24 * 3600)
    await saleInstance.sendTransaction({
      gas: 914366353,
      gasPrice: 1,
      value: 1,
      from: accounts[5]
    })
    let oldBalance = myBalance
    myBalance = parseInt(await songToken.balanceOf.call(accounts[5]))
    expect(parseInt(myBalance)).to.be.equal(1.1 * rate + oldBalance)
  })

  it('07. Should not be possible to get presale Bonus at the last second of presale period (not presale bonus).', async () => {
    // var bonuses = [1,10,2,20,3,30,4,40]
    await saleInstance.SetTestNow(10 * 24 * 3600)
    await saleInstance.sendTransaction({
      gas: 914366353,
      gasPrice: 1,
      value: 1,
      from: accounts[5]
    })
    let oldBalance = myBalance
    myBalance = parseInt(await songToken.balanceOf.call(accounts[5]))
    expect(parseInt(myBalance)).to.be.equal(1 * rate + oldBalance)
  })

  it('08. Should be possible to get first period bonus at the last second of it', async () => {
    // var bonuses = [1,10,2,20,3,30,4,40]
    await saleInstance.SetTestNow((10 + 2) * 24 * 3600)
    await saleInstance.sendTransaction({
      gas: 914366353,
      gasPrice: 1,
      value: 1,
      from: accounts[5]
    })
    let oldBalance = myBalance
    myBalance = parseInt(await songToken.balanceOf.call(accounts[5]))
    expect(parseInt(myBalance)).to.be.equal(1.2 * rate + oldBalance)
  })

  it('09. Should be possible to get second period bonus at the last second of it', async () => {
    // var bonuses = [1,10,2,20,3,30,4,40]
    await saleInstance.SetTestNow((10 + 2 + 3) * 24 * 3600)
    await saleInstance.sendTransaction({
      gas: 914366353,
      gasPrice: 1,
      value: 1,
      from: accounts[5]
    })
    let oldBalance = myBalance
    myBalance = parseInt(await songToken.balanceOf.call(accounts[5]))
    expect(parseInt(myBalance)).to.be.equal(1.3 * rate + oldBalance)
  })

  it('10. Should be possible to get third period bonus at the last second of it', async () => {
    // var bonuses = [1,10,2,20,3,30,4,40]
    await saleInstance.SetTestNow((10 + 2 + 3 + 4) * 24 * 3600)
    await saleInstance.sendTransaction({
      gas: 914366353,
      gasPrice: 1,
      value: 1,
      from: accounts[5]
    })
    let oldBalance = myBalance
    myBalance = parseInt(await songToken.balanceOf.call(accounts[5]))
    expect(parseInt(myBalance)).to.be.equal(1.4 * rate + oldBalance)
  })

  it('11. Should be possible to buy tokens at the last moment of Main Sale. No bonus apply.', async () => {
    // var bonuses = [1,10,2,20,3,30,4,40]
    await saleInstance.SetTestNow(20 * 24 * 3600)
    await saleInstance.sendTransaction({
      gas: 914366353,
      gasPrice: 1,
      value: 1,
      from: accounts[5]
    })
    let oldBalance = myBalance
    myBalance = parseInt(await songToken.balanceOf.call(accounts[5]))
    expect(parseInt(myBalance)).to.be.equal(1 * rate + oldBalance)
  })

  it('12. Should NOT be possible to buy tokens after sales ends. One second later', async () => {
    // var bonuses = [1,10,2,20,3,30,4,40]
    await saleInstance.SetTestNow(20 * 24 * 3600 + 1)
    expect(
      saleInstance.sendTransaction({
        gas: 914366353,
        gasPrice: 1,
        value: 1,
        from: accounts[5]
      })
    ).to.be.eventually.rejected
  })

  it('13. Volume should show amount of sold tokens and be equal to buyer ballance', async () => {
    let res = await saleInstance.GetStats.call()
    expect(parseInt(res[1])).to.be.equal(myBalance)
  })

  it('14. Contribution should show 8 wei. This is total amount for which tokens were bought.', async () => {
    let res = await saleInstance.GetStats.call()
    expect(parseInt(res[0])).to.be.equal(8)
  })
})
