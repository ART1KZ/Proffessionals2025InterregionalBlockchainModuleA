// SPDX-License-Identifier: MIT

pragma solidity 0.8.29;

import "../ERC20Bundle.sol";

contract SystemToken is ERC20 {
    constructor() ERC20("Professional", "PROFI") {
        _mint(msg.sender, 100000);
    }

    function decimals() public pure override returns (uint8) {
        return 12;
    }
}
