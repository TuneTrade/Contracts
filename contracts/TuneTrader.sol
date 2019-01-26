pragma solidity ^0.5.0;
/* pragma experimental ABIEncoderV2; */


// import "./StandardToken.sol";
// import "./Crowdsale.sol";
import "./SongCrowdsale.sol";
import "./SongERC20.sol";
import "./Interface.sol";
import "./SongsLib.sol";


contract TuneTrader {

    enum Type {Song,Band,Influencer}

    address payable public owner;
    IContractStorage DS;

    constructor(IContractStorage _storage) public {
        DS = _storage;
        
        DS.registerName("ContractOwner");
        DS.registerName("userToSongICO");
        DS.registerName("songToSale");
        DS.registerName("Songs");
        DS.registerName("songOwner");
        DS.registerName("songExist");
        DS.registerName("songIndex");
        DS.registerName("usersSongs");

        owner = msg.sender;
        /* AddSong("Poor Little Fool","Ricky Nelson","Rock",uint8(Type.Song),"testwebsite.com",10000,"TST","This is Test Description","soundcloud.com",false,0); */
        /* AddSong("Rolling in the Deep","Adele","Rock",uint8(Type.Song),"testwebsite.com",10000,"TST","This is Test Description","soundcloud.com",false,0); */
    }
    function AddICO(
        address payable _wallet,
        uint256 _teamTokens,uint256[] memory  constraints,
        uint256 _price, uint256 _durationDays,
        uint _presaleduration,uint8[] memory  _bonuses,uint256 assignedTokens) public
	{
    /* require (constraints.length == 5); */
        require(DS.GetAddress(DS.key(msg.sender,'userToSongICO'))!=address(0x0),"No Song assigned to this msg.sender to create ICO" );
        // require (userToSongICO[msg.sender] != address(0x0),"No Song assigned to this msg.sender to create ICO");
        SongERC20 songToken = SongERC20(DS.GetAddress(DS.key(msg.sender,'userToSongICO')));
        SongCrowdSale saleContract = new SongCrowdSale(_price,_wallet,songToken,_teamTokens, constraints, _durationDays, _presaleduration,_bonuses);

        songToken.AssignICOTokens(address(saleContract),assignedTokens);

        DS.SetAddress(DS.key(address(songToken),'songToSale'),address(saleContract));
        DS.SetAddress(DS.key(msg.sender,'userToSongICO'),address(0x0));
    }

    function RemoveSong(address _song) public {
    require(_song != address(0));
    SongsLib.RemoveSong(DS,_song, owner);
    }

    function AddSong (
        string  memory _name,
        string  memory _author,
        string  memory _genre,
        uint8 _entryType,string  memory _website,uint _totalSupply,string memory  _symbol,string memory  _description,
        string  memory _soundcloud, string  memory _youtube,bool _ico, uint8 _decimals,uint _id) public
	{

        SongERC20 song = new SongERC20(msg.sender, _totalSupply, _name, _symbol, _decimals,_id);
        song.SetDetails(_author, _genre, _entryType, _website, _soundcloud, _youtube,_description);
        uint index = DS.PushAddress(DS.key('Songs'),address(song));
        DS.SetAddress(DS.key(address(song),"songOwner"),msg.sender);

        
        // songs.push(song);
        DS.SetBool(DS.key(address(song),"songExist"),true);
        // songExist[song] = true;
        DS.SetUint(DS.key(address(song),"songIndex"),index);
        // songIndex[song] = songs.length;

        if (_ico) {
            DS.SetAddress(DS.key(msg.sender,'userToSongICO'),address(song));
            // userToSongICO[msg.sender] = address(song);
        }
        DS.PushAddress(DS.key(msg.sender,'usersSongs'),address(song));
        // usersSongs[msg.sender].push(address(song));
        // userSongIndex[song] = usersSongs[msg.sender].length;
    }

    function GetMySongs() public view returns(address[] memory)
    {
        return DS.GetAddressTable(DS.key(msg.sender,'usersSongs'));
        // return usersSongs[msg.sender];
    }
    function GetSongs() public view returns (address[] memory)
    {
        return DS.GetAddressTable(DS.key('Songs'));
        // return songs;
    }

    function Test(address song) public view returns (uint,uint,address) {
        return SongsLib.SongsLength(DS,song);
    }

    function GetICO(address song) public view returns(address ico)
    {
        require (DS.GetAddress(DS.key(song,'songToSale')) != address(0x0),"There is no sale for this song");
        // require (songToSale[song] != address(0x0),"There is no sale for this song");
        return DS.GetAddress(DS.key(song,'songToSale'));
        // return songToSale[song];
    }

    function GetContractOwner() public view returns (address payable ) {
        return owner;
    }

}
