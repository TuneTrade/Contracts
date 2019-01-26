pragma solidity 0.5.0;

interface TTManager {
	function tokenFallback(address _tokenSender, uint _value, bytes calldata _data) external;
}

interface IContractStorage {
	
    function GetBool(bytes32 _key) external view returns (bool);
    function GetAddress(bytes32 _key) external view returns (address);
    function GetUint(bytes32 _key) external view returns (uint);

    function SetBool(bytes32 _key, bool val) external;
    function SetAddress(bytes32 _key, address val) external;
    function SetUint(bytes32 _key, uint val) external ;

    function DelBool(bytes32 _key) external;
    function DelAddress(bytes32 _key) external;
    function DelUint(bytes32 _key) external;

    function PushAddress(bytes32 key, address val) external returns (uint);
    function GetAddressTable(bytes32 key) external view returns (address[] memory);
    function GetAddressFromTable(bytes32 key, uint index) external view returns (address);
    function SetAddressInTable(bytes32 key, uint index, address val) external;
    function GetAddressTableLength(bytes32 key) external view returns (uint);
    function DelLastAddressInTable(bytes32 key) external returns(uint);

    function key(string calldata name) external view returns(bytes32) ;
    function key(uint index,string calldata name) external view returns(bytes32) ;
    function key(address adr,string calldata name) external view returns(bytes32) ;

    function registerName(string calldata  name) external;


}