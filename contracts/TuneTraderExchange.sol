pragma solidity 0.5.0;

import "./helpers/Ownable.sol";
import "./TTPositionManager.sol";
import "./interfaces/IContractStorage.sol";

/**
 * @title TuneTraderExchange
 */
contract TuneTraderExchange is Ownable {
	address[] public positionsAddresses;

	mapping (address => bool) public positionExist;
	mapping (address => uint256) public positionIndex;

	IContractStorage public DS;

	event ReceivedTokens(uint256 volume, address tokenSender, address tokenAddress);
	event NewPosition(address token, uint256 volume, bool buySell, uint256 cost, address owner);
	event PositionClosed(address indexed position);
	event PositionCancelled(address indexed position);

	/**
	 * @dev TuneTraderExchange Constructor
	 */
	constructor (address _DS) public {
		DS = IContractStorage(_DS);
		DS.registerName("positions");
		DS.registerName("positionExist");
		DS.registerName("positionIndex");
	}

	// -----------------------------------------
	// SETTERS
	// -----------------------------------------

	function addPosition(address token, uint256 volume, bool buySell, uint256 cost) public payable {
		require(buySell == false || msg.value == cost, "Buying positions must be created with ETH");

		TTPositionManager manager = (new TTPositionManager).value(msg.value)(token, volume, buySell, cost, msg.sender);
		uint256 index = DS.pushAddress(DS.key("positions"),address(manager));
		DS.setBool(DS.key(address(manager), "positionExist"),true);
		DS.setUint(DS.key(address(manager), "positionIndex"),index);

		emit NewPosition(token, volume, buySell, cost, msg.sender);
	}

	function terminatePosition(bool closedOrCancelled) external {
		require((DS.getBool(DS.key(msg.sender, "positionExist")) == true), "Position must exist on the list");

		uint256 index = DS.getUint(DS.key(msg.sender, "positionIndex"));
		uint256 maxIndex = getPositionsCount() - 1;

		if (index < maxIndex) {
			address miAddr = DS.getAddressFromTable(DS.key("positions"), maxIndex);
			DS.setUint(DS.key(miAddr, "positionIndex"), index);
			DS.setAddressInTable(DS.key("positions"), index, miAddr);
		}

		DS.delLastAddressInTable(DS.key("positions"));
		DS.delUint(DS.key(msg.sender, "positionIndex"));
		DS.delBool(DS.key(msg.sender, "positionExist"));

		if (closedOrCancelled == true) {
			emit PositionClosed(msg.sender);
		} else {
			emit PositionCancelled(msg.sender);
		}
	}

	// -----------------------------------------
	// GETTERS
	// -----------------------------------------

	function getPositions() public view returns (address[] memory) {
		return DS.getAddressTable(DS.key("positions"));
	}

	function getPositionsCount() public view returns (uint256) {
		return DS.getAddressTable(DS.key("positions")).length;
	}

	function tokenFallback(address _tokenSender, uint256 _value) public {
		emit ReceivedTokens(_value, _tokenSender, msg.sender);
	}
}