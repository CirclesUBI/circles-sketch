pragma solidity ^0.4.10;

import "./CirclesToken.sol";

import "ds-token/token.sol";
import "ds-math/math.sol";

contract CirclesHub is DSMath {

    uint constant LIMIT_EPOCH = 3600;

    struct EdgeWeight {
        uint limit;
        uint value;
        uint lastTouched;
    }

    mapping (address => CirclesToken) public userToToken;
    mapping (address => address) public tokenToUser;

    mapping (address => bool) isValidator;

    mapping (address => mapping (address => EdgeWeight)) public edges;

    function time() returns (uint) { return block.timestamp; }

    // No exit allowed. Once you create a personal token, you're in for good.
    function join() {
        assert(address(userToToken[msg.sender]) == 0);
        var token = new CirclesToken(msg.sender);
        userToToken[msg.sender] = token;
        tokenToUser[address(token)] = msg.sender;
    }

    function register() {
        isValidator[msg.sender] = true;
    }

    // Trust does not have to be reciprocated. 
    // (e.g. I can trust you but you don't have to trust me)
    function trust(address node, bool yes, uint limit) {
        assert(address(tokenToUser[node]) != 0 || isValidator[node]);
        edges[msg.sender][node] = yes ? EdgeWeight(limit, 0, time()) : EdgeWeight(0, 0, 0);

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

            address nextNode;

            if (currentValidator != 0) {
                nextNode = currentValidator;
                currentValidator = 0;
            }
            else {
                nextNode = token;
            }

            assert(edges[node][nextNode].lastTouched != 0);

            edges[node][nextNode].value = time() - edges[node][nextNode].lastTouched < LIMIT_EPOCH ? 
                edges[node][nextNode].value + wad : 0;

            edges[node][nextNode].lastTouched = time();
            
            assert(edges[node][nextNode].limit >= edges[node][nextNode].value);

            if (isValidator[node]) {
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
