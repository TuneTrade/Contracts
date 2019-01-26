pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./TTPositionManager.sol";
import "./Interface.sol";
// import "./UL.sol";


contract TuneTraderExchange is Ownable
{
    event ReceivedTokens(uint256 volume, address tokenSender, address tokenAddress);
    event NewPosition(address token, uint256 volume, bool buySell, uint256 cost, address owner);
    event PositionClosed(address indexed position);
    event PositionCancelled(address indexed position);
    mapping (address => bool) positionExist;
    address[] positionsAddresses;
    mapping (address => uint256) positionIndex;
    IContractStorage DS;

    constructor(IContractStorage val) public {
        DS = val;
        owner = msg.sender;
        DS.registerName("positions");
        DS.registerName("positionExist");
        DS.registerName("positionIndex");
    }
    function AddPosition(address token, uint256 volume, bool buySell, uint256 cost) public payable 
    {
        require(buySell == false || msg.value == cost, "Buying positions must be created with ETH");
        
        TTPositionManager manager = (new TTPositionManager).value(msg.value)(token, volume, buySell, cost, msg.sender);
        // Position memory newPosition =  Position(token, volume, BuySell, now, cost, msg.sender, address(manager));
        uint index = DS.PushAddress(DS.key("positions"),address(manager));
        DS.SetBool(DS.key(address(manager),"positionExist"),true);
        DS.SetUint(DS.key(address(manager),"positionIndex"),index);
        // positionExist[address(manager)] = true;
        // positionIndex[address(manager)] = positionsAddresses.length - 1; 
        emit NewPosition(token, volume, buySell, cost, msg.sender);
    }

    function PositionsCount () public view returns (uint256) {
        return DS.GetAddressTable(DS.key("positions")).length;
    }

    function GetPositions () public view returns (address[] memory ) {
        return DS.GetAddressTable(DS.key("positions"));
    }


    function tokenFallback(address _tokenSender, uint _value, bytes memory  _data) public {
        emit ReceivedTokens(_value, _tokenSender, msg.sender);
    }



    function TerminatePosition(bool closedOrCancelled) external {
        require ((DS.GetBool(DS.key(msg.sender,"positionExist")) == true),"Position must exist on the list");
        uint256 index = DS.GetUint(DS.key(msg.sender,"positionIndex"));
        uint256 maxIndex = PositionsCount() - 1;

        if (index < maxIndex) {
            address miAddr = DS.GetAddressFromTable(DS.key("positions"),maxIndex);
            DS.SetUint(DS.key(miAddr,"positionIndex"),index);
            // positionIndex[positionsAddresses[maxIndex]] = index;
            DS.SetAddressInTable(DS.key("positions"),index,miAddr);
            // positionsAddresses[index] = positionsAddresses[maxIndex];
        }
        DS.DelLastAddressInTable(DS.key("positions"));
        DS.DelUint(DS.key(msg.sender,"positionIndex"));
        DS.DelBool(DS.key(msg.sender,"positionExist"));
        // delete positionsAddresses[maxIndex];
        // delete positionIndex[msg.sender];
        // delete positionExist[msg.sender];
        // positionsAddresses.length = positionsAddresses.length - 1;

        if (closedOrCancelled == true ) {
            emit PositionClosed(msg.sender);
        } else {
            emit PositionCancelled(msg.sender);
        }
        
    }



}