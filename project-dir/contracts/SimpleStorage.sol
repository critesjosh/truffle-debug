pragma solidity ^0.4.0;

contract SimpleStorage {
    uint public storedData;

    function set(uint x) public {
        storedData = x + 1;
    }
}