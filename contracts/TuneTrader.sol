pragma solidity 0.5.0;

import "./SongCrowdsale.sol";
import "./SongERC20.sol";
import "./SongsLib.sol";
import "./IContractStorage.sol";

/**
 * @title TuneTrader
 */
contract TuneTrader is Ownable {
	// the user should pay service fee in TXT for creating a new token and ICO
    uint256 public tokenCreationFeeTXT;
    uint256 public icoCreationFeeTXT;

	// the x percent of investments (ETH) should go to the platform as a service fee
    uint256 public icoInvestmentsFee;

	// the admin can change fee after 30 days after the last change date
    uint256 public lastFeeChangedAt;
    uint256 public constant delayForChangeFee = 30 days;

	// the admin can disable fees for creating token and ico
    bool public txtFeesEnabled;

	// the address of the TXT token in Mainnet
	address public constant txtToken = 0xA57a2aD52AD6b1995F215b12fC037BffD990Bc5E;

	IContractStorage public DS;

	enum Type { Song, Band, Influencer }

	/**
	 * @dev TuneTrader Constructor
	 */
	constructor (IContractStorage _storage, uint256 _tokenCreationFeeTXT, uint256 _icoCreationFeeTXT, uint256 _icoInvestmentsFee) public Ownable(msg.sender) {
	    require(_tokenCreationFeeTXT != 0 && _icoCreationFeeTXT != 0, "TuneTrader: the fees should be bigger then 0");

        tokenCreationFeeTXT = _tokenCreationFeeTXT;
		icoCreationFeeTXT = _icoCreationFeeTXT;
		icoInvestmentsFee = _icoInvestmentsFee;
        txtFeesEnabled = true;
		lastFeeChangedAt = block.timestamp;

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

	/**
	 * @dev fallback function
	 * receiving ETH fee from the all crowdsales
	 */
	function () external payable {
		// received ETH from crowdsale
	}

	// -----------------------------------------
	// SETTERS
	// -----------------------------------------

	function addICO(
		address payable _wallet,
		uint256 _teamTokens,
		uint256[] memory _constraints,
		uint256 _price,
		uint256 _durationDays,
		uint256 _presaleDuration,
		uint8[] memory _bonuses,
		uint256 assignedTokens
	)
		public
  	{
  	    require(_validateTokenPurchasing(icoCreationFeeTXT), "addICO: for creating the ICO user need to pay txt fee");
		require(DS.getAddress(DS.key(msg.sender, "userToSongICO")) != address(0), "addICO: no Song assigned to this msg.sender to create ICO");

		address songToken = DS.getAddress(DS.key(msg.sender, "userToSongICO"));
		address saleContract = SongsLib.addICO(
			_price,
			_wallet,
			IERC20(songToken),
			_teamTokens,
			_constraints,
			_durationDays,
			_presaleDuration,
			_bonuses,
			msg.sender,
			icoInvestmentsFee
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
	    require(_validateTokenPurchasing(tokenCreationFeeTXT), "addSong: for creating the token user need to pay txt fee");

		address song = address(new SongERC20(msg.sender, _totalSupply, _name, _symbol, _decimals, _id));
		ISongERC20(song).setDetails(_author, _genre, _entryType, _website, _soundcloud, _youtube, _description);

		uint256 index = DS.pushAddress(DS.key("Songs"), song);

		DS.setAddress(DS.key(song, "songOwner"), msg.sender);
		DS.setBool(DS.key(song, "songExist"), true);
		DS.setUint(DS.key(song, "songIndex"), index);

		if (_ico) {
			DS.setAddress(DS.key(msg.sender, "userToSongICO"), song);
		}

		DS.pushAddress(DS.key(msg.sender, "usersSongs"), song);
	}

    function addExistingToken(address _songToken, address _songOwner) external onlyOwner {
        uint256 index = DS.pushAddress(DS.key("Songs"), _songToken);

		DS.setAddress(DS.key(_songToken, "songOwner"), _songOwner);
		DS.setBool(DS.key(_songToken, "songExist"), true);
		DS.setUint(DS.key(_songToken, "songIndex"), index);

		DS.pushAddress(DS.key(_songOwner, "usersSongs"), _songToken);
    }

	function removeSong(address _song) external {
		require(_song != address(0), "removeSong: invalid song address");
		SongsLib.removeSong(DS, _song, owner());
	}

	function disableFees() external onlyOwner {
	    txtFeesEnabled = !txtFeesEnabled;
	}

    function changeFees(uint256 _tokenCreationFeeTXT, uint256 _icoCreationFeeTXT, uint256 _icoInvestmentsFee) external onlyOwner {
        require(_tokenCreationFeeTXT != 0 && _icoCreationFeeTXT != 0, "changeFees: the new fees should be bigger than 0");
        require(block.timestamp >= lastFeeChangedAt + delayForChangeFee, "changeFees: the owner cant change the fee now");
        require(_validateFeeChanging(tokenCreationFeeTXT, _tokenCreationFeeTXT), "changeFees: the new fee should be bigger from old fee max in 1 percent");
        require(_validateFeeChanging(icoCreationFeeTXT, _icoCreationFeeTXT), "changeFees: the new fee should be bigger from old fee max in 1 percent");
        require(icoInvestmentsFee + 1 >= _icoInvestmentsFee, "changeFees: the new fee should be bigger from old fee max in 1 percent");

        tokenCreationFeeTXT = _tokenCreationFeeTXT;
        icoCreationFeeTXT = _icoCreationFeeTXT;
        icoInvestmentsFee = _icoInvestmentsFee;
        lastFeeChangedAt = block.timestamp;
    }

    function withdrawTokens(uint256 amount, address receiver) external onlyOwner {
        IERC20(txtToken).transfer(receiver, amount);
    }

    function withdrawEth(uint256 weiAmount, address payable receiver) external onlyOwner {
        receiver.transfer(weiAmount);
    }

    // -----------------------------------------
	// INTERNAL
	// -----------------------------------------

	function _validateFeeChanging(uint256 oldFee, uint256 newFee) private pure returns (bool) {
        uint256 onePercentOfOldFee = oldFee / 100;
        return (oldFee + onePercentOfOldFee >= newFee);
	}

    function _validateTokenPurchasing(uint256 feeAmount) private returns (bool) {
        if (txtFeesEnabled) {
            return IERC20(txtToken).transferFrom(msg.sender, owner(), feeAmount);
        } else {
	        return true;
        }
    }

	// -----------------------------------------
	// GETTERS
	// -----------------------------------------

	function getSongs() external view returns (address[] memory) {
		return DS.getAddressTable(DS.key("Songs"));
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
}