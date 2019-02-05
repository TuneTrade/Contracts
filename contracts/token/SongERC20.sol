pragma solidity 0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
import "../interfaces/ISongERC20.sol";
import "../interfaces/ITuneTraderManager.sol";

/**
 * @title SongERC20 token
 * @dev The token of Song which contain info about song and about the ERC20 basic token
 */
contract SongERC20 is ERC20Detailed, ERC20Burnable, ISongERC20 {
	address public owner;
	address public tuneTrader;

	uint256 public id;
	uint256 public creationTime;

	string public author;
	string public genre;
	string public website;
	string public soundcloud;
	string public youtube;
	string public description;

	bool public icoTokensAssigned;

	enum Type { Song, Band, Influencer }
	Type public entryType;

	/**
	 * @dev modifier, that only the tune trader address can call method
	 */
	modifier onlyTuneTrader {
		require(msg.sender == tuneTrader, "onlyTuneTrader: Only the contract administrator can execute this function");
		_;
	}

	/**
	 * @dev SongERC20 Constructor
	 */
	constructor (
		address _owner,
		uint256 _supply,
		string memory _name,
		string memory _symbol,
		uint8 _decimals,
		uint256 _id
	)
		public ERC20Detailed(_name, _symbol, _decimals)
	{
		id = _id;
		owner = _owner;
		creationTime = now;
		_mint(_owner, _supply);
		tuneTrader = msg.sender;
	}

	// -----------------------------------------
	// SETTERS
	// -----------------------------------------

	/**
	 * @dev set details of songERC20 token
	 * @return true if transaction successed
	 */
	function setDetails(
		string calldata _author,
		string calldata _genre,
		uint8 _entryType,
		string calldata _website,
		string calldata _soundcloud,
		string calldata _youtube,
		string calldata _description
	)
		external returns (bool)
	{
		author = _author;
		genre = _genre;
		entryType = Type(_entryType);
		website = _website;
		soundcloud = _soundcloud;
		youtube = _youtube;
		description = _description;

		return true;
	}

	/**
	 * @dev the method will call the tokenFallback method from TTPositionManager contract
	 */
	function transfer(address to, uint256 value) public returns (bool) {
		super.transfer(to,value);

		if (isContract(to)) {
			ITuneTraderManager(to).tokenFallback(msg.sender, value);
		}

		return true;
	}

	/**
	 * @dev assing tokens to ICO contract
	 */
	function assignICOTokens(address _ico, uint256 _amount) external onlyTuneTrader {
		require(icoTokensAssigned == false, "assignICOTokens: TuneTrader already has assigned the tokens");

		_transfer(owner, _ico, _amount);
		icoTokensAssigned = true;
	}

	// -----------------------------------------
	// GETTERS
	// -----------------------------------------

	/**
	 * @dev check if the _addr is a contract or just a basic address
	 */
	function isContract(address _addr) internal view returns (bool) {
		uint256 length;
		assembly {
			//retrieve the size of the code on target address, this needs assembly
			length := extcodesize(_addr)
		}

		return (length > 0);
	}

	/**
	 * @dev get details of SongERC20 token
	 */
	function getDetails() external view returns (
		string memory,
		string memory,
		uint8,
		string memory,
		string memory,
		string memory,
		string memory,
		uint256
	) {
		return (
			author,
			genre,
			uint8(entryType),
			website,
			soundcloud,
			youtube,
			description,
			id
		);
	}

	/**
	 * @dev get details of ERC20 standard of SongERC20 token
	 */
	function getTokenDetails() external view returns (
		address,
		uint256,
		string memory,
		string memory,
		uint256,
		uint256
	) {
		return (
			owner,
			totalSupply(),
			name(),
			symbol(),
			decimals(),
			creationTime
		);
	}
}