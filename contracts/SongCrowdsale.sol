pragma solidity 0.5.0;

import "./interfaces/IERC20.sol";
import "./helpers/SafeMath.sol";
import "./helpers/Ownable.sol";

/**
 * @title SongCrowdSale
 * @dev This is Song ICO sale contract based on Open Zeppelin Crowdsale contract.
 * @dev It's purpose is to sell song tokens in main sale and presale.
 */
contract SongCrowdSale is Ownable {
	using SafeMath for uint256;

	uint256 public rate;
	uint256 public weiRaised;
	uint256 public teamTokens;

	uint256 public minPreSaleETH;
	uint256 public minMainSaleETH;

	uint256 public maxEth;
	uint256 public maxCap;
	uint256 public minCap;

	uint256 public durationDays;
	uint256 public preSaleDays;
	uint256 public preSaleEnd;
	uint256 public saleEnd;

	uint256 public bonusPresalePeriod;
	uint256 public firstPeriod;
	uint256 public secondPeriod;
	uint256 public thirdPeriod;

	uint256 public bonusPreSaleValue;
	uint256 public bonusFirstValue;
	uint256 public bonusSecondValue;
	uint256 public bonusThirdValue;

	uint256 public saleStart;
	uint256 public volume;
	uint256 public phase = 1;

	// The token being sold
	IERC20 public token;

	// Address where funds will collected
	address payable public wallet;

	bool public closed;
	bool public refundAvailable;
	bool public isRefundable;

	enum State { PreSale, Campaign, Ended, Refund, Closed }

	mapping (address => uint256) public collectedFunds;

	bool public debug = true;
	uint256 public testNow = 0;

	/**
	 * Event for token purchase logging
	 * @param purchaser who paid for the tokens
	 * @param beneficiary who got the tokens
	 * @param value weis paid for purchase
	 * @param amount amount of tokens purchased
	 */
	event TokenPurchase (
		address indexed purchaser,
		address indexed beneficiary,
		uint256 value,
		uint256 amount
	);

	/**
	 * @dev SongCrowdsale Constructor
	 */
	constructor (
		uint256 _rate,
		address payable _wallet,
		IERC20 _song,
		uint256 _teamTokens,
		uint256[] memory constraints,
		uint256 _duration,
		uint256 _presaleduration,
		uint8[] memory bonuses,
		address _owner
	) public Ownable(_owner) {
		require(_rate > 0, "SongCrowdSale: the rate should be bigger then zero");
		require(_wallet != address(0), "SongCrowdSale: invalid wallet address");
		require(address(_song) != address(0), "SongCrowdSale: invalid SongERC20 token address");

		rate = _rate;
		wallet = _wallet;
		token = _song;
		minPreSaleETH = constraints[0];
		minMainSaleETH = constraints[1];
		maxEth = constraints[2];
		maxCap = constraints[3];
		minCap = constraints[4];
		durationDays = _duration;
		preSaleDays = _presaleduration;
		saleStart = _now();
		preSaleEnd = saleStart + (preSaleDays * 24 * 60 * 60);
		saleEnd = preSaleEnd + (durationDays * 24 * 60 * 60);
		teamTokens = _teamTokens;

		if (bonuses.length == 8) {
			// The bonus periods for presale and main sale must be smaller or equal than presale and mainsail themselves
			require(bonuses[0] <= preSaleDays, "SongCrowdSale: the presale bonus period must be smaller than presale period");
			require((bonuses[2] + bonuses [4] + bonuses[6]) <= durationDays, "SongCrowdSale: the main sale bonus period must be smaller then main sale period");

			_defineBonusValues(bonuses[1], bonuses[3], bonuses[5], bonuses[7]);
			_defineBonusPeriods(bonuses[0], bonuses[2], bonuses[4], bonuses[6]);
		}

		if (minPreSaleETH > 0 || minMainSaleETH > 0) {
			isRefundable = true;
		}
	}

	/**
	 * @dev fallback function ***DO NOT OVERRIDE***
	 * Note that other contracts will transfer fund with a base gas stipend
	 * of 2300, which is not enough to call buyTokens. Consider calling
	 * buyTokens directly when purchasing tokens from a contract.
	 */
	function () external payable {
		buyTokens(msg.sender);
	}

	/**
	 * @dev low level token purchase ***DO NOT OVERRIDE***
	 * @param _beneficiary Address performing the token purchase
	 */
	function buyTokens(address _beneficiary) public payable {
		_preValidatePurchase(_beneficiary, msg.value);

		if (refundAvailable == true || _campaignState() == State.Refund) {
			if (refundAvailable == false) {
				refundAvailable = true;
			}

			msg.sender.transfer(msg.value);
		} else {
			uint256 weiAmount = msg.value;
			uint256 tokens = _getTokenAmount(weiAmount);

			_processPurchase(_beneficiary, tokens);
			_updatePurchasingState(_beneficiary, weiAmount, tokens);
			_postValidatePurchase();

			emit TokenPurchase(
				msg.sender,
				_beneficiary,
				weiAmount,
				tokens
			);
		}
	}

	// -----------------------------------------
	// SETTERS
	// -----------------------------------------

	/**
	 * @dev refund invested amount if the crowdsale has finished and the refund is available
	 */
	function refund() external {
		require(collectedFunds[msg.sender] > 0, "refund: user must have some funds to get refund");
		require(refundAvailable || _campaignState() == State.Refund, "refund: refund must be available or Campaing must be in Refund State");

		uint256 toRefund = collectedFunds[msg.sender];
		collectedFunds[msg.sender] = 0;

		if (refundAvailable == false) {
			refundAvailable = true;
		}

		msg.sender.transfer(toRefund);
	}

	/**
	 * @dev only the owner can change the wallet address
	 * @return true if transaction successed
	 */
	function changeWallet(address payable _newWallet) public onlyOwner returns (bool) {
		require(_newWallet != address(0), "changeWallet: the new wallet address is invalid");
		wallet = _newWallet;

		return true;
	}

	/**
	 * @dev the wallet address can withdraw all funds in this contract after if the crowdasle finished
	 * @return true if transaction successed
	 */
	function withdrawFunds() public returns (bool) {
		require(msg.sender == wallet, "withdrawFunds: only wallet address can withdraw funds");
		require(_campaignState() == State.Ended, "withdrawFunds: sale must be ended to receive funds");

		wallet.transfer(address(this).balance);
		closed = true;

		return true;
	}

	/**
	 * @dev set the test block.timestamp value (debug mode only)
	 */
	function setTestNow(uint256 _testNow) public onlyOwner {
		testNow = _testNow;
	}

	// -----------------------------------------
	// INTERNAL
	// -----------------------------------------

	/**
	 * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
	 * Use `super` in contracts that inherit from Crowdsale to extend their validations.
	 * Example from CappedCrowdsale.sol's _preValidatePurchase method:
	 *     super._preValidatePurchase(beneficiary, weiAmount);
	 *     require(weiRaised().add(weiAmount) <= cap);
	 * @param _beneficiary Address performing the token purchase
	 * @param _weiAmount Value in wei involved in the purchase
	 */
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) private view {
		require(_beneficiary != address(0), "_preValidatePurchase: beneficiary can not be the zero address");
		require(_weiAmount > 0, "_preValidatePurchase: wei Amount must be greater than zero");
		require(_campaignState() != State.Ended, "_preValidatePurchase: the campaign is already ended");
		require(refundAvailable == false, "_preValidatePurchase: the sale is in refund state");
	}

	/**
	 * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
	 * tokens.
	 * @param _beneficiary Address receiving the tokens
	 * @param _tokenAmount Number of tokens to be purchased
	 */
	function _processPurchase(address _beneficiary, uint256 _tokenAmount) private {
		_deliverTokens(_beneficiary, _tokenAmount);
	}

	/**
	 * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
	 * its tokens.
	 * @param _beneficiary Address performing the token purchase
	 * @param _tokenAmount Number of tokens to be emitted
	 */
	function _deliverTokens(address _beneficiary, uint256 _tokenAmount) private {
		token.transfer(_beneficiary, _tokenAmount);

		if (isRefundable == false) {
			_forwardFunds();
		}
	}

	/**
	 * @dev Determines how ETH is stored/forwarded on purchases.
	 */
	function _forwardFunds() private {
		wallet.transfer(msg.value);
	}

	/**
	 * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
	 * conditions are not met.
	 */
	function _postValidatePurchase() private view {
		if (maxEth > 0) {
			require(weiRaised < maxEth, "_postValidatePurchase: can not raise more than the max Eth");
		}

		if (maxCap > 0) {
			require(volume < maxCap, "_postValidatePurchase: can not sell more tokens than the max cap");
		}

		require(teamTokens <= _balanceOf(address(this)), "_postValidatePurchase: sale is not possible because there must be enough tokens for a team");
	}

	/**
	 * @dev Override for extensions that require an internal state to check for validity (current user contributions,
	 * etc.)
	 * @param _beneficiary Address receiving the tokens
	 * @param _weiAmount Value in wei involved in the purchase
	 * @param _tokenAmount value which investor bought
	 */
	function _updatePurchasingState(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) private {
		volume = volume.add(_tokenAmount);
		weiRaised = weiRaised.add(_weiAmount);
		collectedFunds[_beneficiary] = collectedFunds[_beneficiary].add(_weiAmount);
	}

	/**
	 * @return the state of the campaign
	 */
	function _campaignState() private view returns (State _state) {
		if (refundAvailable == true) {
			return State.Refund;
		}

		if (closed) {
			return State.Closed;
		}

		if (_now() <= preSaleEnd) {
			return State.PreSale;
		}

		if (_now() > preSaleEnd && _now() <= saleEnd) {
			if (weiRaised < minPreSaleETH) {
				return State.Refund;
			} else {
				return State.Campaign;
			}
		}
		if (weiRaised < minMainSaleETH) {
			return State.Refund;
		}

		if (minCap > 0 && volume < minCap && _now() > saleEnd) {
			return State.Refund;
		}

		return State.Ended;
	}

	/**
	 * @return the value of tokens based on the _weiAmount
	 */
	function _getTokenAmount(uint256 _weiAmount) private view returns (uint256) {
		uint256 tokenAmount = _weiAmount.mul(rate);
		return tokenAmount.mul(100 + _currentBonusValue()).div(100);
	}

	/**
	 * @dev set the bonus values
	 */
	function _defineBonusValues(uint8 value1, uint8 value2, uint8 value3, uint8 value4) private returns (bool) {
		bonusPreSaleValue = value1;
		bonusFirstValue = value2;
		bonusSecondValue = value3;
		bonusThirdValue = value4;

		return true;
	}

	/**
	 * @dev set the bonus periods
	 */
	function _defineBonusPeriods(uint8 period1,uint8 period2,  uint8 period3, uint8 period4) private returns (bool) {
		bonusPresalePeriod = period1;
		firstPeriod = period2;
		secondPeriod = period3;
		thirdPeriod = period4;

		return true;
	}

	/**
	 * @return the current timestamp
	 */
	function _now() private view returns (uint256) {
		if (debug == true) {
			return testNow;
		} else {
			return block.timestamp;
		}
	}

	/**
	 * @return the bonus amount based on the current timestamp
	 */
	function _currentBonusValue() private view returns (uint256) {
		if (_campaignState() == State.PreSale) {
			if (_now() <= (saleStart + (bonusPresalePeriod * 24 * 60 * 60))) {
				return bonusPreSaleValue;
			}

			return 0;
		}

		if (_campaignState() == State.Campaign) {
			if (_now() > ((preSaleEnd + (firstPeriod + secondPeriod + thirdPeriod) * 24 * 3600 ))) return 0;
			if (_now() > ((preSaleEnd + (firstPeriod + secondPeriod) * 24 * 3600 ))) return bonusThirdValue;
			if (_now() > ((preSaleEnd + (firstPeriod) * 24 * 3600 ))) return bonusSecondValue;
			if (_now() > (preSaleEnd)) return bonusFirstValue;

			return 0;
		}

		return 0;
	}

	/**
	 * @return the token balance of the _who
	 */
	function _balanceOf(address _who) private view returns (uint256) {
		return token.balanceOf(_who);
	}

	// -----------------------------------------
	// GETTERS
	// -----------------------------------------

	/**
	 * @return the token address
	 */
	function getToken() external view returns (address) {
		return address(token);
	}

	/**
	 * @return the token balance of this contract without team tokens amount
	 */
	function getBalance() external view returns (uint256) {
		return token.balanceOf(address(this)).sub(teamTokens);
	}

	/**
	 * @return the current state of this crowdsale
	 */
	function getCampaignState() external view returns (string memory) {
		if (_campaignState() == State.PreSale) return "Presale";
		if (_campaignState() == State.Refund) return "Refund";
		if (_campaignState() == State.Campaign) return "Main Sale";
		if (_campaignState() == State.Ended) return "Ended";
		if (_campaignState() == State.Closed) return "Closed";
	}

	/**
	 * @return calculated value for this _weiAmount, _decimals and _rate
	 */
	function getTokensForWei(uint256 _weiAmount, uint256 _decimals, uint256 _rate) external pure returns (
		uint256,
		uint256,
		uint256,
		uint256
	) {
		uint256 tokensAmount;
		uint256 minitokensAmount;
		uint256 base = 10;

		minitokensAmount = _rate.mul(base**_decimals).mul(_weiAmount).div(10**18);
		tokensAmount = minitokensAmount.div(base**_decimals);

		uint256 valueInWei = minitokensAmount.mul(10**18).div(10**_decimals).div(_rate);
		uint256 weiToReturn = _weiAmount.sub(valueInWei);

		return (
			minitokensAmount,
			tokensAmount,
			valueInWei,
			weiToReturn
		);
	}

	/**
	 * @return the information about the crowdsale sale
	 */
	function getSaleInformation() external view returns (
		uint256,
		address,
		address,
		uint256,
		uint256,
		uint256,
		uint256,
		uint256,
		uint256,
		uint256
	) {
		return (
			rate,
			wallet,
			address(token),
			teamTokens,
			minPreSaleETH,
			minMainSaleETH,
			maxEth,minCap,
			durationDays,
			preSaleDays
		);
	}

	/**
	 * @return the stats of the current state
	 */
	function getStats() external view returns (
		uint256,
		uint256,
		uint8,
		uint256
	) {
		uint256 bonus = _currentBonusValue();
		return (
			weiRaised,
			volume,
			uint8(phase),
			bonus
		);
	}
}