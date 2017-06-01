pragma solidity ^0.4.10;

import "./CirclesToken.sol";

contract GroupRules {

    address public admin;
    address public vault;

    function canConvert(CirclesToken token, address guy, uint wad) constant returns (bool);
    function convertRate(CirclesToken token, address guy, uint wad) constant returns (uint128);
    function taxRate(CirclesToken token, address guy, uint wad) constant returns (uint128);
}