// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAddressManager {
    function governance() external view returns (address); // contract IGovernance at ABI level
    function member() external view returns (address);
    function payouts() external view returns (address);
    function proposal() external view returns (address);
    function setContracts(
        address _governance,
        address _member,
        address _proposal,
        address _payouts
    ) external;
}
