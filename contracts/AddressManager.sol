// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IAddressManager } from "./interfaces/IAddressManager.sol";

contract AddressManager is IAddressManager {
    address private _governance;
    address private _member;
    address private _proposal;
    address private _payouts;

    event Log(string message);

    receive() external payable {}

    function governance() external view returns (address) {
        return _governance;
    }

    function member() external view returns (address) {
        return _member;
    }

    function payouts() external view returns (address) {
        return _payouts;
    }

    function proposal() external view returns (address) {
        return _proposal;
    }

    function setContracts(
        address _g,
        address _m,
        address _p,
        address _pay
    ) external {
        emit Log("Starting setContracts");
        _governance = _g;
        _member = _m;
        _proposal = _p;
        _payouts = _pay;
        emit Log("Completed setContracts");
    }
}
