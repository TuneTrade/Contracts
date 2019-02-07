pragma solidity 0.5.0;

/**
 * @title ITuneTraderManager
 * @dev Interface for interacting with TTManager contract
 */
interface ITuneTraderManager {
  function tokenFallback(address _tokenSender, uint256 _value) external;
}