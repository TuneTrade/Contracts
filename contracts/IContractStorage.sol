pragma solidity 0.5.0;

/**
 * @title IContractStorage
 * @dev Interface for interacting with ContractStorage contract
 */
interface IContractStorage {
	function getBool(bytes32 _key) external view returns (bool);
	function getAddress(bytes32 _key) external view returns (address);
	function getUint(bytes32 _key) external view returns (uint256);

	function setBool(bytes32 _key, bool val) external;
	function setAddress(bytes32 _key, address val) external;
	function setUint(bytes32 _key, uint256 val) external;

	function delBool(bytes32 _key) external;
	function delAddress(bytes32 _key) external;
	function delUint(bytes32 _key) external;

	function pushAddress(bytes32 key, address val) external returns (uint256);
	function getAddressTable(bytes32 key) external view returns (address[] memory);
	function getAddressFromTable(bytes32 key, uint256 index) external view returns (address);
	function setAddressInTable(bytes32 key, uint256 index, address val) external;
	function getAddressTableLength(bytes32 key) external view returns (uint256);
	function delLastAddressInTable(bytes32 key) external returns (uint256);

	function key(string calldata name) external view returns (bytes32);
	function key(uint256 index,string calldata name) external view returns (bytes32);
	function key(address adr,string calldata name) external view returns (bytes32);

	function registerName(string calldata name) external;
}