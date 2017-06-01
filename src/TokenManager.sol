pragma solidity ^0.4.10;

import "./CirclesToken.sol";

contract TokenManager {

    mapping (address => CirclesToken) public circlesUsers;
    mapping (address => address) public circlesTokens;

    mapping (address => mapping (address => bool)) public edges;

    function join() {
        assert(address(circlesUsers[msg.sender]) == 0);
        var token = new CirclesToken(msg.sender);
        circlesUsers[msg.sender] = token;
        circlesTokens[address(token)] = msg.sender;
    }

    function trust(address node, bool yes) {
        assert(address(circlesUsers[node]) != 0);
        assert(address(circlesUsers[msg.sender]) != 0);
        edges[msg.sender][node] = yes;
    }

    function transferThrough(address[] nodes, address[] tokens, uint wad) {
        assert(nodes.length == tokens.length);
        var length = nodes.length;

        for (var x = 0; x < length; x++) {
            
            assert(circlesTokens[tokens[x]] != 0);
            
            var node = nodes[x];
            var token = CirclesToken(tokens[x]);

            token.transferFrom(msg.sender, node, wad);

            if (x + 1 < length) {
                var tokenBeneficiary = circlesTokens[address(token)];
                assert(edges[node][tokenBeneficiary]);

                var nextToken = CirclesToken(tokens[x+1]);
                nextToken.transferFrom(node, msg.sender, wad);
            }
        }
    }

}
