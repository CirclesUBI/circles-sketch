pragma solidity ^0.4.10;

import "./TokenManager.sol";
import "./CirclesToken.sol";
import "./GroupRules.sol";
import "ds-test/test.sol";

contract TestableTokenManager is TokenManager {

    function mintFor(CirclesToken token, address guy, uint wad) {
        token.mint(cast(wad));
        token.transfer(guy, cast(wad));
    }
}

contract CirclesUser {

    TestableTokenManager circles;
    CirclesToken public token;

    function CirclesUser(TestableTokenManager circles_) {
        circles = circles_;
    }

    function doJoin() {
        circles.join();
        token = circles.circlesTokens(this);
    }

    function doTransfer(address dst, uint wad) {
        token.transfer(dst, wad);
    }

    function doTransferThrough(address[] nodes, address[] tokens, uint wad) {
        circles.transferThrough(nodes, tokens, wad);
    }

    function doTrust(address node, bool yes) {
        circles.trust(node, yes);
    }

    function doConvert(CirclesToken src, DSToken dst, uint wad){
        circles.convert(src, dst, wad);
    }
}

contract ConstantGroup is GroupRules {
    address public admin;
    address public vault;

    function ConstantGroup(address admin_, address vault_) {
        admin = admin_;
        vault = vault_;
    }

    function canConvert(CirclesToken token, address guy, uint wad) constant returns (bool) {
        return true;
    }

    function convertRate(CirclesToken token, address guy, uint wad) constant returns (uint128) {
        return .9 ether;
    }

    function taxRate(CirclesToken token, address guy, uint wad) constant returns (uint128) {
        return .1 ether;
    }

}

contract TokenManagerTest is DSTest {

    TestableTokenManager circles;

    CirclesUser user1;
    CirclesUser user2;
    CirclesUser user3;
    CirclesUser user4;

    ConstantGroup rules;

    function setUp() {
        circles = new TestableTokenManager();
        user1 = new CirclesUser(circles);
        user2 = new CirclesUser(circles);
        user3 = new CirclesUser(circles);
        user4 = new CirclesUser(circles);
        
        rules = new ConstantGroup(this, this);
    }

    function doubleEdge(CirclesUser user1, CirclesUser user2) {
        user1.doTrust(user2, true);
        user2.doTrust(user1, true);
    }

    function testTransferThrough() {
        user1.doJoin();
        user2.doJoin();
        user3.doJoin();
        user4.doJoin();

        circles.mintFor(user1.token(), user1, 100 ether);
        circles.mintFor(user2.token(), user2, 100 ether);
        circles.mintFor(user3.token(), user3, 100 ether);
        circles.mintFor(user4.token(), user4, 100 ether);

        doubleEdge(user1, user2);
        doubleEdge(user2, user3);
        doubleEdge(user3, user4);

        address[] memory nodes = new address[](3);
        address[] memory tokens = new address[](3);

        nodes[0] = user2;
        nodes[1] = user3;
        nodes[2] = user4;

        tokens[0] = user1.token();
        tokens[1] = user2.token();
        tokens[2] = user3.token();

        user1.doTransferThrough(nodes, tokens, 100 ether);

        assertEq(user1.token().balanceOf(user2), 100 ether);
        assertEq(user1.token().balanceOf(user1), 0);
        
        assertEq(user2.token().balanceOf(user2), 0);
        assertEq(user2.token().balanceOf(user3), 100 ether);
        
        assertEq(user3.token().balanceOf(user3), 0);
        assertEq(user3.token().balanceOf(user4), 100 ether);
        
        assertEq(user4.token().balanceOf(user4), 100 ether);   
    }

    function testTransferThroughOthersTokens() {
        user1.doJoin();
        user2.doJoin();
        user3.doJoin();
        user4.doJoin();

        circles.mintFor(user2.token(), user1, 100 ether);
        circles.mintFor(user3.token(), user3, 100 ether);

        doubleEdge(user1, user2);
        doubleEdge(user2, user3);
        doubleEdge(user3, user4);

        address[] memory nodes = new address[](2);
        address[] memory tokens = new address[](2);

        nodes[0] = user3;
        nodes[1] = user4;

        tokens[0] = user2.token();
        tokens[1] = user3.token();

        user1.doTransferThrough(nodes, tokens, 100 ether);

        assertEq(user2.token().balanceOf(user3), 100 ether);
        assertEq(user2.token().balanceOf(user1), 0);

        assertEq(user3.token().balanceOf(user3), 0);
        assertEq(user3.token().balanceOf(user4), 100 ether);
    }

    function testGroup() {
        circles.group(rules, "DTW", "Detroit Coin");
        assert(address(circles.groupTokens(address(rules))) != 0);
    }

    function testConvert() {
        circles.group(rules, "DTW", "Detroit Coin");
        var token = circles.groupTokens(address(rules));
        user1.doJoin();
        circles.mintFor(user1.token(), user1, 100 ether);
        user1.doConvert(user1.token(), token, 100 ether);
        assertEq(token.balanceOf(user1), 90 ether);
        assertEq(token.balanceOf(this), 10 ether);
    }
}