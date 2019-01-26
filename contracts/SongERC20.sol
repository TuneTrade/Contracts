pragma solidity ^0.5.0;

import "./StandardToken.sol";
import "./Ownable.sol";
import "./Interface.sol";

contract SongERC20 is StandardToken, Ownable
{
    enum Type {Song,Band,Influencer}

    string public author;
    string public genre;
    address TuneTrader;
    Type public entryType; //true - band, false - song
    uint public creationTime;
    string public website;
    string soundcloud;
    string youtube;
    string description;
    uint256 id;

    string public name;
    string public symbol;

    modifier onlyTuneTrader {
        require (msg.sender == TuneTrader,'Only contract administrator can execute this function');
        _;
    }
    constructor (address payable _owner, uint _supply,string memory _name, string memory  _symbol, uint8 _decimals,uint256 _id)  public
    {
    owner = _owner;
    totalSupply_ = _supply;
    creationTime = now;
    id = _id;
    balances[owner] = totalSupply_;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    TuneTrader = msg.sender;
    }

    function AssignICOTokens(address _ico, uint256 _amount) public onlyTuneTrader {

        require(balances[owner] >= _amount);
        balances[owner] = balances[owner].sub(_amount);
        balances[_ico] = balances[_ico].add(_amount);
    }

    function SetDetails(string  memory _author, string  memory _genre, uint8 _entryType, string  memory _website, string  memory _soundcloud, string  memory _youtube,string memory  _description) public returns (bool) {
        author = _author;
        genre = _genre;
        entryType = Type(_entryType);
        website = _website;
        soundcloud = _soundcloud;
        youtube = _youtube;
        description = _description;
    }

  	function GetOwner() public view returns (address) {
    return owner;
  	}

  function GetDetails() public view returns (string memory _author, string memory _genre, uint8  _entryType, string memory _website, string memory _soundcloud, string memory _youtube, string memory _description, uint256 _id)
  {
    return (author, genre, uint8(entryType), website, soundcloud,youtube, description, id);
  }

  function GetTokenDetails() public view returns (address _owner, uint256 _supply, string  memory _name, string  memory  _symbol, uint256 _decimals,uint256 _creationTime) {
    return (owner,totalSupply_,name,symbol,decimals,creationTime);
  }

  function transfer(address to, uint256 value) public returns (bool){
    super.transfer(to,value);
    if(isContract(to)) {
      bytes memory empty;
      TTManager(to).tokenFallback(msg.sender,value,empty);
    }
  }


  function isContract(address _addr) internal view returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
    }
    return (length>0);
}

}
