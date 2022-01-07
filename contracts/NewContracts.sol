// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Contract.sol";

contract NewContracts {
    Contract One;
    Contract Two;

    constructor() {
        One = new Contract("Contract One", "ONE");
        Two = new Contract("Contract Two", "TWO");
    }

    function OnePreMint() public {
        One.preMintName();
    }

    function TwoPreMint() public {
        Two.preMintName();
    }
}