pragma solidity ^0.4.10;

import "ds-token/token.sol";

contract CirclesToken is DSToken("") {

    address public recipient;

    uint public lastTouched;
    uint public factor = 1736111111111111; // ~1050 tokens per week

    function CirclesToken(address recipient_) {
        recipient = recipient;
        lastTouched = now;
    }

    function look() returns (uint) {
        var period = now - lastTouched;
        return factor * period;
    }

    // the universal basic income part
    function update() {
        var gift = look();
        this.mint(cast(gift));
        this.push(recipient, cast(gift));
        lastTouched = now;
    }

    function transferFrom(
        address src, address dst, uint wad
    ) returns (bool) {
        update();

        // TokenManager doesn't need approval to transferFrom
        if (msg.sender == owner) {
            assert(_balances[src] >= wad);
        
            _balances[src] = sub(_balances[src], wad);
            _balances[dst] = add(_balances[dst], wad);
        
            Transfer(src, dst, wad);
        
            return true;
        } else {
            return super.transferFrom(src, dst, wad);
        }
        
    }

    function transfer(address dst, uint wad) returns (bool) {
        update();
        return super.transfer(dst, wad);
    }


    function approve(address guy, uint wad) returns (bool) {
        update();
        return super.approve(guy, wad);
    }

    function totalSupply() constant returns (uint256) {
        return super.totalSupply() + look();
    }

    function balanceOf(address src) constant returns (uint256) {
        var balance = super.balanceOf(src);

        if (src == recipient) {
            balance = add(balance, look());
        }

        return balance;
    }
}