var TuneTraderExchangeContract = artifacts.require('TuneTraderExchange')
var SongERC20 = artifacts.require('SongERC20')
var TuneTrader = artifacts.require('TuneTrader')
var TTPositionManager = artifacts.require('TTPositionManager')

require('babel-polyfill')

var chai = require('chai')
var chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
expect = chai.expect

var TuneTraderExchange
var TuneTraderContract
var TTManagerContract
var songToken

contract('Test TuneTrader Exchange Contract Full Buy Tests ', async accounts => {
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
        1,
        { from: accounts[2] }
      )
    ).to.be.eventually.fulfilled
    let mySongs = await TuneTraderContract.GetMySongs.call({ from: accounts[2] })
    songToken = await SongERC20.at(mySongs[0])
  })
  // address token, uint256 volume, bool BuySell, uint256 cost
  it('03. Add Song to Exchange.', async () => {
    var buySell = true
    var cost = web3.utils.toWei('10', 'ether')
    cost = cost.toString()
    var volume = '200'
    await expect(
      TuneTraderExchange.AddPosition(songToken.address, volume, buySell, cost, {
        from: accounts[1],
        value: cost,
        gasPrice: 1
      })
    ).to.be.eventually.fulfilled
    let positions = await TuneTraderExchange.GetPositions.call()
    expect(positions.length).to.be.equal(1)
  })

  it('04. Get List of Positions. Should be 1', async () => {
    var positions = await TuneTraderExchange.GetPositions()
    expect(positions.length).to.be.equal(1)
    TTManagerContract = await TTPositionManager.at(positions[0])
  })

  it('05. Get Position Data. Should be marked as active', async () => {
    let data = await TTManagerContract.GetPositionData()
    expect(data[7], 'Position should be marked as active because ETH was transfered').to.be.true
    expect(data[2], 'It should be Buy position').to.be.true
  })

  it('06. Transfer required token number. Should be accepted. ', async () => {
    var volume = 200
    let managerTokenBalanceBefore = await songToken.balanceOf(TTManagerContract.address)
    let buyerTokenBalanceBefore = await songToken.balanceOf(accounts[1])
    let sellerTokenBalanceBefore = await songToken.balanceOf(accounts[2])

    await expect(songToken.transfer(TTManagerContract.address, volume, { from: accounts[2] })).to.be.fulfilled

    // let data = await TTManagerContract.GetPositionData()

    // let managerTokenBalanceAfter = await songToken.balanceOf(TTManagerContract.address)
    let buyerTokenBalanceAfter = await songToken.balanceOf(accounts[1])
    let sellerTokenBalanceAfter = await songToken.balanceOf(accounts[2])

    expect(managerTokenBalanceBefore.toNumber()).to.be.equal(0)
    expect(buyerTokenBalanceBefore.toNumber()).to.be.equal(0)
    expect(sellerTokenBalanceBefore.toNumber()).to.be.equal(2000)

    expect(buyerTokenBalanceAfter.toNumber()).to.be.equal(200)
    expect(sellerTokenBalanceAfter.toNumber()).to.be.equal(2000 - volume)
  })

  it('07. It should not be possible to read position data anymore.', async () => {
    await expect(TTManagerContract.GetPositionData()).to.be.eventually.rejected
    let positions = await TuneTraderExchange.GetPositions.call()
    expect(positions.length, 'There should be zero positions in Token Exchange contract').to.be.equal(0)
  })
})
