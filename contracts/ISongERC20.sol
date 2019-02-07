pragma solidity 0.5.0;

/**
 * @title ISongERC20 interface
 */
interface ISongERC20 {
	function assignICOTokens(address _ico, uint256 _amount) external;

	function setDetails(
		string calldata,
		string calldata,
		uint8 _entryType,
		string calldata,
		string calldata,
		string calldata,
		string calldata
	)
		external returns (bool);

	function getDetails() external view returns (
		string memory,
		string memory,
		uint8,
		string memory,
		string memory,
		string memory,
		string memory,
		uint256
	);

	function getTokenDetails() external view returns (
		address,
		uint256,
		string memory,
		string memory,
		uint256,
		uint256
	);
}