// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import "../ERC20Bundle.sol";

contract WrapToken is ERC20 {
    constructor() ERC20("RTKCoin", "RTK") {
        _mint(msg.sender, 20000000 * 10**decimals());
    }

    function decimals() public pure override returns (uint8) {
        return 12;
    }

    function price() public pure returns (uint256) {
        return 1 ether;
    }

    function buy() public payable {
        require(msg.value >= 0.01 ether, "Min value to buy is 0.01 ether");
        _mint(msg.sender, msg.value * 10**decimals() / price());
    }

}
