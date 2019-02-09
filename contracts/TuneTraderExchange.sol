pragma solidity 0.5.0;

import "./Ownable.sol";
import "./TTPositionManager.sol";
import "./IContractStorage.sol";

/**
 * @title TuneTraderExchange
 */
contract TuneTraderExchange is Ownable {
	// for creating an position user need to pay a fee
    uint256 public fee;

	// the admin can change fee after 30 days after the last change date
    uint256 public lastFeeChangedAt;
    uint256 private constant delayForChangeFee = 30 days;

	// the admin can disable fees for creating token and ico
	bool public feeEnabled;

	// the address of created positions
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
	constructor (IContractStorage _storage, uint256 _fee) public Ownable(msg.sender) {
		require(_fee != 0, "TuneTraderExchange: the fee should be bigger then 0");

		fee = _fee;
		feeEnabled = true;

		DS = _storage;
		DS.registerName("positions");
		DS.registerName("positionExist");
		DS.registerName("positionIndex");
	}

	// -----------------------------------------
	// SETTERS
	// -----------------------------------------

	function addPosition(address token, uint256 volume, bool isBuyPosition, uint256 cost) public payable {
	    if (isBuyPosition == false) {
	        require(msg.value == fee, "addPosition: for creationg a positions user must pay a fee");
	    } else {
	        require(msg.value == cost + fee, "the buying positions must include some ETH in the msg plus fee");
	    }

		address manager = address((new TTPositionManager).value(msg.value - fee)(token, volume, isBuyPosition, cost, msg.sender));
		uint256 index = DS.pushAddress(DS.key("positions"), manager);
		DS.setBool(DS.key(manager, "positionExist"), true);
		DS.setUint(DS.key(manager, "positionIndex"), index);

		emit NewPosition(token, volume, isBuyPosition, cost, msg.sender);
	}

	function terminatePosition(bool closedOrCancelled) external {
		require((DS.getBool(DS.key(msg.sender, "positionExist")) == true), "terminatePosition: Position must exist on the list");

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

    function withdrawEth(uint256 weiAmount, address payable receiver) external onlyOwner {
        receiver.transfer(weiAmount);
    }

	function changeFee(uint256 _newFee) external onlyOwner {
        require(block.timestamp >= lastFeeChangedAt + delayForChangeFee, "changeFee: the owner can't change the fee now");
        require(_validateFeeChanging(fee, _newFee), "changeFee: the new fee should be bigger from old fee max in 1 percent");

        fee = _newFee;
        lastFeeChangedAt = block.timestamp;
    }

	function disableFee() external onlyOwner {
	    feeEnabled = !feeEnabled;
	}

	// -----------------------------------------
	// INTERNAL
	// -----------------------------------------

	function _validateFeeChanging(uint256 oldFee, uint256 newFee) private pure returns (bool) {
        uint256 onePercentOfOldFee = oldFee / 100;
        return (oldFee + onePercentOfOldFee >= newFee);
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