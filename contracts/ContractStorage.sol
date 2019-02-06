pragma solidity 0.5.0;

import "./helpers/Ownable.sol";
import "./interfaces/IContractStorage.sol";

/**
 * @title ContractStorage
 */
contract ContractStorage is Ownable, IContractStorage {
	mapping (address => bool) public authorizedAddress;
	mapping (bytes32 => bool) public boolStorage;
	mapping (bytes32 => address) public addressStorage;
	mapping (bytes32 => uint256) public uintStorage;
	mapping (bytes32 => address[]) public addressTable;
	mapping (string => bool) internal varNames;

	event UnauthorizedAccess(address account);
	event AuthorizeAddress(address account);

	modifier onlyAuthorized() {
		if (isOwner() == false && isAddressAuthorized(msg.sender) == false) {
			emit UnauthorizedAccess(msg.sender);
		}

		require(isOwner() == true || isAddressAuthorized(msg.sender) == true, "onlyAuthorized: the sender is not authorized or not the owner for using the ContractStorage");
		_;
	}

	// -----------------------------------------
	// SETTERS
	// -----------------------------------------

	function authorizeAddress(address account) external onlyOwner {
		authorizedAddress[account] = true;
		emit AuthorizeAddress(account);
	}

	function removeAuthorizedAddress(address account) external onlyOwner {
		authorizedAddress[account] = false;
	}

	function registerName(string calldata name) external {
		require(varNames[name] == false, _error("registerName: variable is registered: ", name));
		varNames[name] = true;
	}

	function setBool(bytes32 _key, bool value) external onlyAuthorized {
		boolStorage[_key] = value;
	}

	function setAddress(bytes32 _key, address account) external onlyAuthorized {
		addressStorage[_key] = account;
	}

	function setUint(bytes32 _key, uint256 value) external onlyAuthorized {
		uintStorage[_key] = value;
	}

	function setAddressInTable(bytes32 _key, uint256 index, address account) external onlyAuthorized {
		addressTable[_key][index] = account;
	}

	function pushAddress(bytes32 _key, address account) external onlyAuthorized returns (uint256) {
		addressTable[_key].push(account);

		return addressTable[_key].length;
	}

	function delLastAddressInTable(bytes32 _key) external onlyAuthorized returns (uint256) {
		addressTable[_key].length--;

		return addressTable[_key].length;
	}

	function delBool(bytes32 _key) external onlyAuthorized {
		delete boolStorage[_key];
	}

	function delAddress(bytes32 _key) external onlyAuthorized {
		delete addressStorage[_key];
	}

	function delUint(bytes32 _key) external onlyAuthorized {
		delete uintStorage[_key];
	}

	// -----------------------------------------
	// INTERNAL
	// -----------------------------------------

	function _error(string memory text, string memory variable) private pure returns (string memory) {
		bytes memory message = abi.encodePacked(text, variable);

		return string(message);
	}

	// -----------------------------------------
	// GETTERS
	// -----------------------------------------

	function isAddressAuthorized(address account) public view returns (bool) {
		return authorizedAddress[account];
	}

	function key(string calldata name) external view returns (bytes32) {
		require(varNames[name], _error("key: variable name not registered:", name));
		return keccak256(abi.encodePacked(name));
	}

	function key(uint256 index, string calldata name) external view returns (bytes32) {
		require(varNames[name], _error("key: ariable name not registered:", name));
		return keccak256(abi.encodePacked(name, index));
	}

	function key(address account, string calldata name) external view returns (bytes32) {
		require(varNames[name], _error("key: ariable name not registered:", name));
		return keccak256(abi.encodePacked(name, account));
	}

	function getBool(bytes32 _key) external view returns (bool) {
		return boolStorage[_key];
	}

	function getAddress(bytes32 _key) external view returns (address) {
		return addressStorage[_key];
	}

	function getUint(bytes32 _key) external view returns (uint256) {
		return uintStorage[_key];
	}

	function getAddressTable(bytes32 _key) external view returns (address[] memory) {
		return addressTable[_key];
	}

	function getAddressFromTable(bytes32 _key, uint256 index) external view returns (address) {
		return addressTable[_key][index];
	}

	function getAddressTableLength(bytes32 _key) external view returns (uint256) {
		return addressTable[_key].length;
	}
}