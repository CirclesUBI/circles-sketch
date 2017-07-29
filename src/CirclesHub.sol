pragma solidity ^0.4.10;

import "./CirclesToken.sol";

import "ds-token/token.sol";
import "ds-math/math.sol";

contract CirclesHub is DSMath {

    mapping (address => CirclesToken) public userToToken;
    mapping (address => address) public tokenToUser;

    mapping (address => bool) validators;

    mapping (address => mapping (address => bool)) public edges;
    

    // No exit allowed. Once you create a personal token, you're in for good.
    function join() {
        assert(address(userToToken[msg.sender]) == 0);
        var token = new CirclesToken(msg.sender);
        userToToken[msg.sender] = token;
        tokenToUser[address(token)] = msg.sender;
    }

    function register() {
        validators[msg.sender] = true;
    }2

    // Trust does not have to be reciprocated. 
    // (e.g. I can trust you but you don't have to trust me)
    function trust(address node, bool yes) {
        assert(address(tokenToUser[node]) != 0 || validators[node]);
        edges[msg.sender][node] = yes;
    }

    // Starting with msg.sender as node 0, 
    // iterates through the nodes list swapping the nth token for the n+1 token
    function transferThrough(address[] nodes, address[] tokens, uint wad) {
        var length = tokens.length;

        uint currentToken = 0;

        address currentValidator;

        for (var x = 0; x < length; x++) {
            
            var node = nodes[x];

            var token = CirclesToken(tokens[currentToken]);

            if (currentValidator != 0) {
                assert(edges[node][currentValidator]);
                currentValidator = 0;
            }
            else {
                assert(edges[node][token]); // node trusts the current token of the mediated transaction
            }

            if (validators[node]) {
                currentValidator = node;
            } else {
                currentToken++;

                token.transferFrom(msg.sender, node, wad);

                if (x + 1 < length) {

                    var nextToken = CirclesToken(tokens[currentToken]);
                    nextToken.transferFrom(node, msg.sender, wad);
                }
            }
            
        }
    }

}
