pragma solidity 0.5.0;

/**
 * @title ITuneTraderExchange
 */
interface ITuneTraderExchange {
	function terminatePosition(bool closedOrCancelled) external;
}