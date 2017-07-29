pragma solidity ^0.4.10;

import "./CirclesToken.sol";

import "ds-token/token.sol";
import "ds-math/math.sol";

contract CirclesHub is DSMath {

    mapping (address => CirclesToken) public userToToken;
    mapping (address => address) public tokenToUser;

    mapping (address => mapping (address => bool)) public edges;

    // No exit allowed. Once you create a personal token, you're in for good.
    function join() {
        assert(address(userToToken[msg.sender]) == 0);
        var token = new CirclesToken(msg.sender);
        userToToken[msg.sender] = token;
        tokenToUser[address(token)] = msg.sender;
    }

    // Trust does not have to be reciprocated. 
    // (e.g. I can trust you but you don't have to trust me)
    function trust(address node, bool yes) {
        assert(address(userToToken[node]) != 0);
        edges[msg.sender][node] = yes;
    }

    // Starting with msg.sender as node 0, 
    // iterates through the nodes list swapping the nth token for the n+1 token
    function transferThrough(address[] nodes, address[] tokens, uint wad) {
        var length = nodes.length;

        for (var x = 0; x < length; x++) {
            
            assert(tokenToUser[tokens[x]] != 0);
            
            var node = nodes[x];
            var token = CirclesToken(tokens[x]);

            var person = token.person();
            assert(edges[node][person]); // node trusts what they're about to receive

            token.transferFrom(msg.sender, node, wad);

            if (x + 1 < length) {

                var nextToken = CirclesToken(tokens[x+1]);
                nextToken.transferFrom(node, msg.sender, wad);
            }
        }
    }

}
