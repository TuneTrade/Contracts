pragma solidity 0.5.0;

import "./SongCrowdsale.sol";
import "./SongERC20.sol";
import "./SongsLib.sol";
import "./IContractStorage.sol";

/**
 * @title TuneTrader
 */
contract TuneTrader is ITuneTraderManager {
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
		uint256[] memory  constraints,
		uint256 _price,
		uint256 _durationDays,
		uint256 _presaleDuration,
		uint8[] memory _bonuses,
		uint256 assignedTokens
	)
		public
    {
		require(DS.getAddress(DS.key(msg.sender, "userToSongICO")) != address(0), "addICO: no Song assigned to this msg.sender to create ICO");

		SongERC20 songToken = SongERC20(DS.getAddress(DS.key(msg.sender, "userToSongICO")));
		SongCrowdSale saleContract = new SongCrowdSale(
			_price,
			_wallet,
			songToken,
			_teamTokens,
			constraints,
			_durationDays,
			_presaleDuration,
			_bonuses,
			msg.sender
		);

		songToken.assignICOTokens(address(saleContract), assignedTokens);

		DS.setAddress(DS.key(address(songToken), "songToSale"), address(saleContract));
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
		SongERC20 song = new SongERC20(msg.sender, _totalSupply, _name, _symbol, _decimals, _id);
		song.setDetails(_author, _genre, _entryType, _website, _soundcloud, _youtube, _description);

		uint256 index = DS.pushAddress(DS.key('Songs'), address(song));

		DS.setAddress(DS.key(address(song), "songOwner"), msg.sender);
		DS.setBool(DS.key(address(song), "songExist"), true);
		DS.setUint(DS.key(address(song), "songIndex"), index);

		if (_ico) {
			DS.setAddress(DS.key(msg.sender, 'userToSongICO'), address(song));
		}

		DS.pushAddress(DS.key(msg.sender, "usersSongs"), address(song));
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
		return SongsLib.songsLength(DS, song);
	}

	function getICO(address song) external view returns (address) {
		require(DS.getAddress(DS.key(song, "songToSale")) != address(0), "getICO: there is no sale for this song");
		return DS.getAddress(DS.key(song, "songToSale"));
	}

	function getContractOwner() public view returns (address payable) {
		return owner;
	}
}