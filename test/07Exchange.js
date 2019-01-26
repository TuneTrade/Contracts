var TuneTraderExchangeContract = artifacts.require('TuneTraderExchange')
var SongERC20 = artifacts.require('SongERC20')
var PositionManager = artifacts.require('TTPositionManager.sol')
var TuneTrader = artifacts.require('TuneTrader')

require('babel-polyfill')

var chai = require('chai')
var chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
expect = chai.expect

var TuneTraderExchange
var TuneTraderContract
var songToken

contract('Test TuneTrader Exchange Contract Basic Tests ', async accounts => {
  it('01. Catch an instance of TuneTraderExchange Smart Contract', async () => {
    TuneTraderExchange = await TuneTraderExchangeContract.deployed()
    TuneTraderContract = await TuneTrader.deployed()
    console.log(' ')
    console.log('    ************************************************************************************')
    console.log('    TuneTrader Contract:    '.blue, TuneTraderExchange.address)
    console.log('    ************************************************************************************')
    console.log(' ')
  })

  it('02. Add New Song so it can be used later to Test EXchange.', async () => {
    var assignTokens = 2000
    var decimals = 18
    await expect(
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
        false,
        decimals,
        1
      )
    ).to.be.eventually.fulfilled
    let mySongs = await TuneTraderContract.GetMySongs.call()
    songToken = await SongERC20.at(mySongs[0])
  })
  // address token, uint256 volume, bool BuySell, uint256 cost
  it('03. Add Song to Exchange.', async () => {
    await expect(
      TuneTraderExchange.AddPosition(songToken.address, 100, true, 200, {
        from: accounts[1],
        value: 200
      })
    ).to.be.eventually.fulfilled
    let count = await TuneTraderExchange.PositionsCount.call()
    await expect(count.toNumber()).to.be.equal(1)
  })
  // 0 address _token,
  // 1 uint256 _volume,
  // 2 bool _buySell,
  // 3 uint256 _created,
  // 4 uint256 _cost,
  // 5 address _customer,
  // 6 address _managerAddress

  it('04. Verify Position #1 Data', async () => {
    let myPositions = await TuneTraderExchange.GetPositions.call()
    let positionContract = await PositionManager.at(myPositions[0])
    let position = await positionContract.GetPositionData()
    expect(position[0]).to.be.equal(songToken.address)
    expect(position[1].toNumber()).to.be.equal(100)
    expect(position[2]).to.be.true
    expect(position[4].toNumber()).to.be.equal(200)
    expect(position[5]).to.be.equal(accounts[1])
    console.log('Manager address: ', position[6])
  })
  it('05. There should be only one position', async () => {
    let myPositions = await TuneTraderExchange.GetPositions.call()
    await expect(myPositions.length).to.be.equal(1)
  })
})
