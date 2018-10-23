# Debugging Truffle Tests

Truffle is really useful for writing and running automated tests on your smart contracts. When you are debugging Truffle tests, how can you determine
why your tests are failing?

In this exercise we are going to go over stepping through Truffle tests using the [Truffle Debugger.](https://truffleframework.com/docs/truffle/getting-started/debugging-your-contracts)

### Getting Started

Navigate to the [project-dir](./project-dir). This directory is the example project directory. In it you will find a SimpleStorage contract, a migrations script to deploy the SimpleStorage contract and a test to make sure that the SimpleStorage contract is behaving as expected.

Read the [simpleStorageTest.js](./project-dir/test/simpleStorageTest.js) file so you understand how the test is operating. 

```
contract('SimpleStorage', async (accounts) => {
    it('Calling set(x) should set storedData in storage to x', async() => {
        let newValue = 2;
        let instance = await SimpleStorage.deployed()
    
        instance.set(newValue, {from: accounts[0]})
        let returnedValue = await instance.storedData.call()
    
        assert.equal(newValue, returnedValue, "The returned value should equal the new value.")
    })
})
```
In the test we are updating the storedData storage variable in the SimpleStorage.sol contract and then retrieving the variable to make sure 
that it updated correctly.

To run the test, in a new terminal window, start `ganache-cli`, or use the [Ganache GUI](https://truffleframework.com/ganache). With ganache-cli running, deploy the contract and run the tests by typing `$ truffle test`. 

Console output:
```
 Contract: SimpleStorage
    1) Calling set(x) should set storedData in storage to x
    > No events were emitted


  0 passing (60ms)
  1 failing

  1) Contract: SimpleStorage
       Calling set(x) should set storedData in storage to x:
     AssertionError: The returned value should equal the new value.: expected 2 to equal { Object (s, e, ...) }
```     

Our test is failing for some reason! It looks like there is an assertion error, but why is this error happening? Let's use the Truffle debugger to investigate.

Navigate back to the terminal that is running ganache-cli, or to the Ganache GUI. We are looking for a transaction hash to give to the debugger so it knows which transaction we want to debug.

Looking at our test file we can see that it is only initiating one transaction, in line 9 when a new value is being set in the contract. The latest transaction hash displayed in the terminal should be this transation:

```
...
eth_sendTransaction
eth_call

  Transaction: 0xb385612f90e0cdca7a239e91a41081bd8cb50fb4eefec9a060ca4b6b6193fa6a
  Gas usage: 41697
  Block Number: 5
  Block Time: Tue Oct 23 2018 14:46:26 GMT-0400 (Eastern Daylight Time)

eth_getTransactionReceipt
eth_getLogs
```

I copy that transaction hash `0xb385612...`. In a new terminal I can run the truffle debugger with `$ truffle debug 0xb385612...` and using the debugger I can step through the transaction and determine where the bug is.  

```
Gathering transaction data...

Addresses affected:
 0xcfcc2c06cf288535aa7b581131f61f9c203b5d10 - SimpleStorage

Commands:
(enter) last command entered (step next)
(o) step over, (i) step into, (u) step out, (n) step next
(;) step instruction, (p) print instruction, (h) print this help, (q) quit
(b) toggle breakpoint, (c) continue until breakpoint
(+) add watch expression (`+:<expr>`), (-) remove watch expression (-:<expr>)
(?) list existing watch expressions
(v) print variables and values, (:) evaluate expression - see `v`


SimpleStorage.sol:

1: pragma solidity ^0.4.0;
2:
3: contract SimpleStorage {
   ^^^^^^^^^^^^^^^^^^^^^^^^

debug(development:0xb385612f...)>
```

I can see the address of the contract as well as instructions about how to navigate through the transaction. I can start stepping through the transaction with 'o'. I can check the current variables and values with 'v'.

```
...
debug(development:0xb385612f...)> o

SimpleStorage.sol:

4:     uint public storedData;
5:
6:     function set(uint x) public {
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

debug(development:0xb385612f...)> v

  storedData: 0

``` 
I continue to step over the transaction. On the next step I can see that when the set(uint x) function is called, the storedData variable is updated to
x + 1. That doesn't seem right. On the next step, the function signature is highlighted again and I can check the state with 'v'.

```
6:     function set(uint x) public {
7:         storedData = x + 1;
                            ^

debug(development:0xb385612f...)> o

SimpleStorage.sol:

4:     uint public storedData;
5:
6:     function set(uint x) public {
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

debug(development:0xb385612f...)> v

           x: 2
  storedData: 3

```
I see that the storedData variable is set to x + 1. This is where the data is being incorrectly modified.

I go back to SimpleStorage.sol and make the appropriate adjustments, deleting the '+ 1'.

Now when I run `$ truffle test`, all test pass.
