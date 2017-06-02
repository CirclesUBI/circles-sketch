pragma solidity ^0.4.10;

import "./CirclesToken.sol";
import "./GroupRules.sol";

import "ds-token/token.sol";
import "ds-math/math.sol";

contract TokenManager is DSMath {

    mapping (address => CirclesToken) public circlesTokens;
    mapping (address => address) public circlesUsers;

    mapping (address => mapping (address => bool)) public edges;

    mapping (address => DSToken) public groupTokens;
    mapping (address => GroupRules) public groupUsers;

    function join() {
        assert(address(circlesTokens[msg.sender]) == 0);
        var token = new CirclesToken(msg.sender);
        circlesTokens[msg.sender] = token;
        circlesUsers[address(token)] = msg.sender;
    }

    function trust(address node, bool yes) {
        assert(address(circlesTokens[node]) != 0);
        assert(address(circlesTokens[msg.sender]) != 0);
        edges[msg.sender][node] = yes;
    }

    function transferThrough(address[] nodes, address[] tokens, uint wad) {
        assert(nodes.length == tokens.length);
        var length = nodes.length;

        for (var x = 0; x < length; x++) {
            
            assert(circlesUsers[tokens[x]] != 0);
            
            var node = nodes[x];
            var token = CirclesToken(tokens[x]);

            token.transferFrom(msg.sender, node, wad);

            if (x + 1 < length) {
                var person = token.person();
                assert(edges[node][person]);

                var nextToken = CirclesToken(tokens[x+1]);
                nextToken.transferFrom(node, msg.sender, wad);
            }
        }
    }


    function group(GroupRules rules, bytes32 symbol, bytes32 name) {
        var token = new DSToken(symbol);
        token.setName(name);
        groupTokens[address(rules)] = token;
        groupUsers[address(token)] = rules;
    }

    function newRules(GroupRules oldRules, GroupRules newRules) {
        assert(address(groupTokens[address(oldRules)]) != 0);
        assert(msg.sender == oldRules.admin());

        var token = groupTokens[address(oldRules)];

        groupTokens[address(newRules)] = token;
        groupUsers[address(token)] = newRules;

        delete groupTokens[address(oldRules)];
    }

    function convert(CirclesToken src, DSToken dst, uint wad) {
        var rules = groupUsers[address(dst)];

        assert(circlesUsers[address(src)] != 0);
        assert(address(rules) != 0);
        assert(rules.canConvert(src, msg.sender, wad));

        var gift = wmul(rules.convertRate(src, msg.sender, wad), cast(wad));
        var tax = wmul(rules.taxRate(src, msg.sender, wad), cast(wad));
        var total = hadd(gift, tax);

        src.transferFrom(msg.sender, this, wad);
        src.burn(cast(wad));

        dst.mint(total);
        dst.push(msg.sender, gift);
        dst.push(rules.vault(), tax);
    }

}
