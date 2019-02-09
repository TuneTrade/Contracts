pragma solidity 0.5.0;

import "./IERC20.sol";
import "./IContractStorage.sol";
import "./SongCrowdsale.sol";

/**
 * @title SongsLib
 */
library SongsLib {
    function addICO(
		uint256 price,
		address payable wallet,
		IERC20 songToken,
		uint256 teamTokens,
		uint256[] calldata constraints,
		uint256 durationDays,
		uint256 presaleDuration,
		uint8[] calldata bonuses,
		address sender,
		uint256 fee
    ) external returns (address) {
        return address(new SongCrowdsale(
			price,
			wallet,
			songToken,
			teamTokens,
			constraints,
			durationDays,
			presaleDuration,
			bonuses,
			sender,
			fee
		));
    }

	function removeSong(IContractStorage DS, address _song, address contractOwner) public {
		require(address(DS) != address(0), "removeSong: contractStorage address is zero");
		require(_song != address(0), "removeSong: song Address can not be zero");
		require(DS.getBool(DS.key(_song, "songExist")), "removeSong: song with this address is not on the list");

		//REMOVE SONG TOKEN
		address songOwner = DS.getAddress(DS.key(_song, "songOwner"));
		require(msg.sender == songOwner || msg.sender == contractOwner, "removeSong: song can be deleted by Administrator or Song Owner only");

		//REMOVE SONG FROM GENERAL SONGS LIST
		uint256 index = DS.getUint(DS.key(_song, "songIndex")) - 1;
		uint256 maxIndex = DS.getAddressTableLength(DS.key("Songs")) - 1;
		address miAddress = DS.getAddressFromTable(DS.key("Songs"), maxIndex);

		DS.setAddressInTable(DS.key("Songs"), index, miAddress);

		if (index < maxIndex) {
			DS.setUint(DS.key(miAddress, "songIndex"), index + 1);
		}

		DS.delLastAddressInTable(DS.key("Songs"));
		DS.delUint(DS.key(_song, "songIndex"));
		DS.setBool(DS.key(_song, "songExist"), false);
	}

	function getSongsLength(IContractStorage DS, address _song) public view returns (uint256, uint256, address) {
		uint256 maxIndex = DS.getAddressTableLength(DS.key("Songs")) - 1;
		address miAddress = DS.getAddressFromTable(DS.key("Songs"), maxIndex);
		uint256 index = DS.getUint(DS.key(_song, "songIndex")) - 1;

		return (
			maxIndex,
			index,
			miAddress
		);
	}
}