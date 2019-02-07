pragma solidity 0.5.0;

import "./SongCrowdsale.sol";
import "./SongERC20.sol";
import "./SongsLib.sol";
import "./IContractStorage.sol";

/**
 * @title TuneTrader
 */
contract TuneTrader {
	IContractStorage public DS;
	address payable public owner;

	enum Type { Song, Band, Influencer }

	/**
	 * @dev TuneTrader Constructor
	 */
	constructor (IContractStorage _storage) public {
		owner = msg.sender;
		DS = _storage;
		DS.registerName("ContractOwner");
		DS.registerName("userToSongICO");
		DS.registerName("songToSale");
		DS.registerName("Songs");
		DS.registerName("songOwner");
		DS.registerName("songExist");
		DS.registerName("songIndex");
		DS.registerName("usersSongs");
	}

	// -----------------------------------------
	// SETTERS
	// -----------------------------------------

	function addICO(
		address payable _wallet,
		uint256 _teamTokens,
		uint256[] memory constraints,
		uint256 _price,
		uint256 _durationDays,
		uint256 _presaleDuration,
		uint8[] memory _bonuses,
		uint256 assignedTokens
	)
		public
  	{
		require(DS.getAddress(DS.key(msg.sender, "userToSongICO")) != address(0), "addICO: no Song assigned to this msg.sender to create ICO");

		address songToken = DS.getAddress(DS.key(msg.sender, "userToSongICO"));
		address saleContract = SongsLib.addICO(
			_price,
			_wallet,
			IERC20(songToken),
			_teamTokens,
			constraints,
			_durationDays,
			_presaleDuration,
			_bonuses,
			msg.sender
		);

		ISongERC20(songToken).assignICOTokens(saleContract, assignedTokens);

		DS.setAddress(DS.key(songToken, "songToSale"), saleContract);
		DS.setAddress(DS.key(msg.sender, "userToSongICO"), address(0));
	}

	function addSong(
		string memory _name,
		string memory _author,
		string memory _genre,
		uint8 _entryType,
		string  memory _website,
		uint256 _totalSupply,
		string memory _symbol,
		string memory _description,
		string memory _soundcloud,
		string memory _youtube,
		bool _ico,
		uint8 _decimals,
		uint256 _id
	)
		public
	{
		address song = address(new SongERC20(msg.sender, _totalSupply, _name, _symbol, _decimals, _id));
		ISongERC20(song).setDetails(_author, _genre, _entryType, _website, _soundcloud, _youtube, _description);

		uint256 index = DS.pushAddress(DS.key('Songs'), song);

		DS.setAddress(DS.key(song, "songOwner"), msg.sender);
		DS.setBool(DS.key(song, "songExist"), true);
		DS.setUint(DS.key(song, "songIndex"), index);

		if (_ico) {
			DS.setAddress(DS.key(msg.sender, 'userToSongICO'), song);
		}

		DS.pushAddress(DS.key(msg.sender, "usersSongs"), song);
	}

	function removeSong(address _song) external {
		require(_song != address(0), "removeSong: invalid song address");
		SongsLib.removeSong(DS, _song, owner);
	}

	// -----------------------------------------
	// GETTERS
	// -----------------------------------------

	function getSongs() external view returns (address[] memory) {
		return DS.getAddressTable(DS.key('Songs'));
	}

	function getMySongs() external view returns (address[] memory) {
		return DS.getAddressTable(DS.key(msg.sender, "usersSongs"));
	}

	function getSongsLength(address song) external view returns (uint, uint, address) {
		return SongsLib.getSongsLength(DS, song);
	}

	function getICO(address song) external view returns (address) {
		require(DS.getAddress(DS.key(song, "songToSale")) != address(0), "getICO: there is no sale for this song");
		return DS.getAddress(DS.key(song, "songToSale"));
	}

	function getContractOwner() public view returns (address payable) {
		return owner;
	}
}