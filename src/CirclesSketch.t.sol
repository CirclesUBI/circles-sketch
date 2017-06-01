pragma solidity ^0.4.10;

import "ds-test/test.sol";

import "./CirclesSketch.sol";

contract CirclesSketchTest is DSTest {
    CirclesSketch sketch;

    function setUp() {
        sketch = new CirclesSketch();
    }

    function testFail_basic_sanity() {
        assert(false);
    }

    function test_basic_sanity() {
        assert(true);
    }
}
