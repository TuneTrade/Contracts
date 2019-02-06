pragma solidity 0.5.0;

import "./helpers/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ITuneTraderExchange.sol";

/**
 * @title TTPositionManager
 */
contract TTPositionManager {
	uint256 public cost;
	uint256 public volume;
	uint256 public created;

	enum Position { Buy, Sell }
	Position public position;

	IERC20 public token;

	address payable owner;
	address public tokenExchange;
	address public tokenReceiver;

	event PositionClosed();
	event PositionCancelled();
	event ReceivedPayment(uint256 weiAmount, address from);
	event ReceivedTokens(uint256 tokenAmount, address tokenOwner, address from);

	/**
	 * @dev TTPositionManager Constructor
	 */
	constructor (address _token, uint256 _volume, bool _isBuyPosition, uint256 _cost, address payable _owner) public payable {
		require(_isBuyPosition == false || msg.value == _cost, "TTPositionManager: the buying positions must include some ETH in the msg");

		owner = _owner;
		token = IERC20(_token);
		volume = _volume;
		position = _isBuyPosition ? Position.Buy : Position.Sell;
		cost = _cost;
		created = block.timestamp;
		tokenExchange = msg.sender;
	}

	// -----------------------------------------
	// SETTERS
	// -----------------------------------------

	function buyTokens() external payable {
		require(position == Position.Sell, "buyTokens: you can buy tokens only from selling positions");
		require(token.balanceOf(address(this)) == volume, "buyTokens: tokens must be already transfered");
		require(msg.value == cost, "buyTokens: you must send exact amount of ETH to buy tokens");

		token.transfer(msg.sender, volume);
		owner.transfer(msg.value);

		emit ReceivedPayment(msg.value, msg.sender);
		emit PositionClosed();

		_removeFromExchange();
	}

	function tokenFallback(address payable _tokenSender, uint256 _value) external {
		require(msg.sender == address(token), "tokenFallback: tokens can be accepted only from designated token contract");

		uint256 balance = token.balanceOf(address(this));
		require(balance == volume, "tokenFallback: contract only accepts exact token amount equal to volume");

		if (position == Position.Buy) {
			require(address(this).balance == cost, "tokenFallback: ETH to buy tokens must be already transfered to the contract");

			// transfering the funds to the seller and to the buyer
			token.transfer(owner, volume);
			_tokenSender.transfer(cost);

			emit PositionClosed();
			emit ReceivedTokens(balance, _tokenSender, msg.sender);

			_removeFromExchange();
		} else {
			emit ReceivedTokens(balance, _tokenSender, msg.sender);
		}
	}

	function cancelPosition() external {
		require(msg.sender == owner, "cancelPosition: only the owner can call this method");

		uint256 balance = token.balanceOf(address(this));
		if (position == Position.Buy) {
			//buyig position. we have to send ETHEREUM back to the owner.
			//the question is what to do when by any chance there are tokens from token contract on this position.
			// We send it to Token Exchange Contract for manual action to be taken.
			if (balance > 0) {
				token.transfer(tokenExchange, balance);
			}
		} else {
			//this is the "Sell" position, sending back all tokens to the owner.
			token.transfer(owner, balance);
		}

		ITuneTraderExchange(tokenExchange).terminatePosition(false);

		emit PositionCancelled();

		selfdestruct(owner);
	}

	// -----------------------------------------
	// INTERNAL
	// -----------------------------------------

	function _removeFromExchange() private {
		ITuneTraderExchange(tokenExchange).terminatePosition(true);
		selfdestruct(owner);
	}

	// -----------------------------------------
	// GETTERS
	// -----------------------------------------

	function getPositionData() external view returns (
		address _token,
		uint256 _volume,
		bool _buyPosition,
		uint256 _created,
		uint256 _cost,
		address payable _customer,
		address _managerAddress,
		bool _active,
		uint256 _tokenBalance,
		uint256 _weiBalance
	) {
		bool active;
		uint256 weiBalance = address(this).balance;
		uint256 tokenBalance = token.balanceOf(address(this));

		if (position == Position.Buy) {
			// this a position when somebody wants to buy tokens. They have to send ETH to make it happen.
			active = weiBalance >= cost ? true : false;
		} else {
			// this is a position when somebody wants to sell tokens.
			active = tokenBalance >= volume ? true : false;
		}

		return (
			address(token),
			volume,
			position == Position.Buy,
			created,
			cost,
			owner,
			address(this),
			active,
			tokenBalance,
			weiBalance
		);
	}
}