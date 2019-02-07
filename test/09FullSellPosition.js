var TuneTraderExchangeContract = artifacts.require('TuneTraderExchange')
var SongERC20 = artifacts.require('SongERC20')
var TuneTrader = artifacts.require('TuneTrader')
var TTPositionManager = artifacts.require('TTPositionManager')

require('babel-polyfill')

var chai = require('chai')
var chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
expect = chai.expect
var BigNumber = require('bignumber.js')
var TuneTraderExchange
var TuneTraderContract
var TTManagerContract
var songToken

contract('Test TuneTrader Exchange Contract FullSell Tests ', async accounts => {
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
        false,
        decimals,
        1,
        { from: accounts[2] }
      )
    ).to.be.eventually.fulfilled
    let mySongs = await TuneTraderContract.getMySongs.call({ from: accounts[2] })
    songToken = await SongERC20.at(mySongs[0])
    console.log(songToken.address)
  })

  it('03. Add Song to Exchange.', async () => {
    var buySell = false
    var cost = web3.utils.toWei('10', 'ether')
    var volume = 200
    await expect(
      TuneTraderExchange.addPosition(songToken.address, volume, buySell, cost, { from: accounts[2], gasPrice: 1 })
    ).to.be.eventually.fulfilled
    let positions = await TuneTraderExchange.getPositions.call()
    expect(positions.length).to.be.equal(1)
  })

  it('04. Get List of Positions. Should be 1', async () => {
    var positions = await TuneTraderExchange.getPositions()
    expect(positions.length).to.be.equal(1)
    TTManagerContract = await TTPositionManager.at(positions[0])
  })

  it('05. Transfer tokens to Position to actitvate it.', async () => {
    var volume = 200
    await expect(songToken.transfer(TTManagerContract.address, volume, { from: accounts[2] })).to.be.eventually
      .fulfilled
    let data = await TTManagerContract.getPositionData()
  })

  it('06. Send Ether to receive tokens', async () => {
    var volume = 200

    let managerTokenBalanceBefore = await songToken.balanceOf(TTManagerContract.address)
    let buyerTokenBalanceBefore = await songToken.balanceOf(accounts[1])
    let sellerTokenBalanceBefore = await songToken.balanceOf(accounts[2])
    var cost = web3.utils.toWei('10', 'ether')
    var balanceBefore = await web3.eth.getBalance(accounts[1])
    var sellerBalanceBefore = await web3.eth.getBalance(accounts[2])

    let tx = await expect(TTManagerContract.buyTokens({ value: cost, gasPrice: 1, from: accounts[1] })).to.be.eventually
      .fulfilled

    let managerTokenBalanceAfter = await songToken.balanceOf(TTManagerContract.address)
    let buyerTokenBalanceAfter = await songToken.balanceOf(accounts[1])
    let sellerTokenBalanceAfter = await songToken.balanceOf(accounts[2])

    await expect(managerTokenBalanceBefore.toNumber(), 'Test 1').to.be.equal(200)
    await expect(buyerTokenBalanceBefore.toNumber(), '2').to.be.equal(0)
    await expect(sellerTokenBalanceBefore.toNumber(), '3').to.be.equal(2000 - volume)

    await expect(managerTokenBalanceAfter.toNumber(), '4').to.be.equal(0)
    await expect(buyerTokenBalanceAfter.toNumber(), '5').to.be.equal(200)
    await expect(sellerTokenBalanceAfter.toNumber(), '6').to.be.equal(2000 - volume)

    var balance = await web3.eth.getBalance(accounts[1])
    var sellerBalance = await web3.eth.getBalance(accounts[2])
    balanceBefore = BigNumber(balanceBefore)
    sellerBalance = BigNumber(sellerBalance)
    sellerBalanceBefore = BigNumber(sellerBalanceBefore)
    console.log('BalanceBefore:', balanceBefore)
    expect(BigNumber(balance).toString(), '7').to.be.equal(
      balanceBefore
        .minus(cost)
        .minus(tx.receipt.gasUsed)
        .toString(),
      '8'
    )
    expect(sellerBalance.toNumber(), '9').to.be.equal(sellerBalanceBefore.plus(cost).toNumber())
    console.log('Balance: ', web3.utils.fromWei(balance, 'ether'))
  })

  it('07. It should not be possible to read position data anymore.', async () => {
    await expect(TTManagerContract.getPositionData(), '1').to.be.eventually.rejected
    let positions = await TuneTraderExchange.getPositions.call()
    expect(positions.length, 'There should be zero positions in Token Exchange contract').to.be.equal(0)
  })
})
