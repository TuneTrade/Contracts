pragma solidity ^0.5.0;

import "./Interface.sol";

contract ContractStorage is IContractStorage {

    event UnauthorizedAccess(address);
    event AuthorizeAddress(address);
    address owner;
    mapping (address => bool) authorizedAddress;
    mapping (bytes32 => bool) boolStorage;
    mapping (bytes32 => address) addressStorage;
    mapping (bytes32 => uint) uintStorage;
    mapping (bytes32 => address[]) addressTable;
    mapping (string => bool) varNames;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require (msg.sender == owner,"Only Contract Owner can execute this function");
        _;
    }

    modifier isAuthorized() {
        if(msg.sender != owner && ! authorizedAddress[msg.sender]) emit UnauthorizedAccess(msg.sender);
        require(msg.sender == owner || authorizedAddress[msg.sender],"User is not authorized to use ContractStorage");
        _;
    }

    function authorizeAddress(address adr) public onlyOwner {
        authorizedAddress[adr] = true;
    }

    function removeAuthorizedAddress(address adr) public onlyOwner {
        authorizedAddress[adr] = false;
    }

    function isAddressAuthorized(address adr) external view returns (bool) {
        return authorizedAddress[adr];
    }

    function error(string memory text, string memory par) internal pure returns (string memory)
    {
        bytes memory message =  abi.encodePacked(text,par);
        return string(message);
    }

    function registerName(string calldata  name) external {
        require (varNames[name]==false,error("Variable is registered: ", name));
        varNames[name] = true;
    }
    function key(string calldata name) external view returns(bytes32) {
        require(varNames[name],error("Variable name not registered:",name));
        return keccak256(abi.encodePacked(name));
    }
    function key(uint index,string calldata name) external view returns(bytes32) {
        require(varNames[name],error("Variable name not registered:",name));
        return keccak256(abi.encodePacked(name,index));
    }

    function key(address addr,string calldata name) external view returns(bytes32) {
        require(varNames[name],error("Variable name not registered:",name));
        return keccak256(abi.encodePacked(name,addr));
    }


    function GetBool(bytes32 _key) public view  returns (bool)
    {
        return boolStorage[_key];
    }

    function GetAddress(bytes32 _key) public view  returns (address)
    {
        return addressStorage[_key];
    }
    
    function GetUint(bytes32 _key) public view  returns (uint)
    {
        return uintStorage[_key];
    }

    function SetBool(bytes32 _key, bool val) public isAuthorized
    {
        boolStorage[_key] = val;
    }

    function SetAddress(bytes32 _key,address val) public isAuthorized
    {
        addressStorage[_key] = val;
    }
    
    function SetUint(bytes32 _key, uint val) public isAuthorized
    {
        uintStorage[_key] = val;
    }


//******/Table functions 
    //Address tables
    function PushAddress(bytes32 _key, address val) public isAuthorized returns (uint)
    {
        addressTable[_key].push(val);
        return addressTable[_key].length;
    }
    function GetAddressTable(bytes32 _key) public view  returns (address[] memory)
    {
        return addressTable[_key];
    }

    function GetAddressFromTable(bytes32 _key, uint index) public view  returns (address){
        return addressTable[_key][index];
    }

    function SetAddressInTable(bytes32 _key, uint index, address val) public isAuthorized {
        addressTable[_key][index] = val;
    }

    function DelLastAddressInTable(bytes32 _key) public isAuthorized returns(uint) {
        addressTable[_key].length--;
        return addressTable[_key].length;
    }

    function GetAddressTableLength(bytes32 _key) external view returns (uint) {
        return addressTable[_key].length;
    }
    

    function DelBool(bytes32 _key) public isAuthorized {
        delete boolStorage[_key];
    }
    function DelAddress(bytes32 _key) public isAuthorized {
        delete addressStorage[_key];
    }
    function DelUint(bytes32 _key) public isAuthorized {
        delete uintStorage[_key];
    }
    
}