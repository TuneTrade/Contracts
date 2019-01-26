pragma solidity ^0.5.0;

import "./Interface.sol";

library SongsLib {

    function SongsLength(IContractStorage DS, address _song) public view returns (uint,uint,address){
        uint maxIndex = DS.GetAddressTableLength(DS.key("Songs")) - 1;
        address miAddress = DS.GetAddressFromTable(DS.key("Songs"),maxIndex);
        uint index = DS.GetUint(DS.key(_song,"songIndex")) - 1;
        // return (maxIndex,0,address(0));
        return (maxIndex,index,miAddress);
    }

    function RemoveSong(IContractStorage DS,address _song, address contractOwner) public {
        require(address(DS) != address(0),"ContractStorage address is zero");
        require(_song != address(0),"Song Address can not be zero");
        require(DS.GetBool(DS.key(_song,"songExist")),"Song with this address is not on the list");
        // require(songExist[_song],"Song with this address is not on the list");

        //REMOVE SONG TOKEN
        address songOwner = DS.GetAddress(DS.key(_song,"songOwner"));
        require (msg.sender == songOwner || msg.sender == contractOwner,"Song can be deleted by Administrator or Song Owner only");

        //REMOVE SONG FROM GENERAL SONGS LIST
        uint index = DS.GetUint(DS.key(_song,"songIndex")) - 1;
        // uint index = songIndex[_song] - 1;
        // uint maxIndex = songs.length;
        uint maxIndex = DS.GetAddressTableLength(DS.key("Songs")) - 1;
        address miAddress = DS.GetAddressFromTable(DS.key("Songs"),maxIndex);
        DS.SetAddressInTable(DS.key("Songs"),index, miAddress);

        if(index < maxIndex) {
            DS.SetUint(DS.key(miAddress,"songIndex"),index+1);
            // songIndex[songs[maxIndex]] = index;
        }
        DS.DelLastAddressInTable(DS.key("Songs"));
        DS.DelUint(DS.key(_song,"songIndex"));
        // delete songIndex[_song];
        DS.SetBool(DS.key(_song,"songExist"),false);

    }
}