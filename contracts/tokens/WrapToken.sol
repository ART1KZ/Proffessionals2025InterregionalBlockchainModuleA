// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WrapToken is ERC20 {
    constructor() ERC20("RTKCoin", "RTK") {
        _mint(msg.sender, 20000000);
    }

    function decimals() public pure override returns(uint8) {
        return 12;
    }
}