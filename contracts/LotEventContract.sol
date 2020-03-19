pragma solidity ^0.5.14;

import "./CommonLibrary.sol";

/**
 @title Represents events that must be tracked against a LOT
 @author Michael Edge
*/
 contract LotEventContract {

    // Mapping from the LOT ID to the array of TRADEITEM IDs (GTIN)
    // I.e. one LOT = many TRADEITEMS, where each TRADEITEM may represent 1 package of coffee for resale, or a batch of labels, etc.
    mapping(uint256 => uint256[]) private tradeItemsForLot;

    // Mapping from the TRADEITEM to the array of events
    mapping(uint256 => CommonLibrary.TradeItemEvent[]) private tradeItemEvents;

    /**
    Keep a record of events against a LOT/TokenId
    */
    function captureTradeItemEvent(
        address owner,
        uint256 LOTID,
        uint256 GTIN,
        string memory action,
        uint256 sourceBizLocationGLN,
        uint256 destinationBizLocationGLN,
        string memory bizStep,
        string memory disposition,
        string memory uom,
        uint256 inputQuantity,
        uint256 outputQuantity,
        string memory tradeItemSupplementaryInfo
    ) public {
        // push the event to the events array
        CommonLibrary.TradeItemEvent[] storage eventArray = tradeItemEvents[GTIN];
        CommonLibrary.TradeItemEvent memory tradeItemEvent = CommonLibrary.TradeItemEvent(
            owner,
            LOTID,
            GTIN,
            action,
            block.timestamp,
            sourceBizLocationGLN,
            destinationBizLocationGLN,
            bizStep,
            disposition,
            uom,
            inputQuantity,
            outputQuantity,
            tradeItemSupplementaryInfo
        );
        eventArray.push(tradeItemEvent);
        // emit the event
        CommonLibrary.emitTradeItemEvent(
            owner,
            LOTID,
            GTIN,
            action,
            block.timestamp,
            sourceBizLocationGLN
            // destinationBizLocationGLN,
            // bizStep,
            // disposition,
            // uom,
            // inputQuantity,
            // outputQuantity
        );
    }

    /**
    Getters
    */

    /**
    Return the number of events that have occurred against a LOT (i.e. commission, transform, observe, etc.)
    */
    function getNumberEventsForTradeItem(uint256 GTIN)
        public
        view
        returns (uint256)
    {
        CommonLibrary.TradeItemEvent[] memory eventArray = tradeItemEvents[GTIN];
        uint256 numberOfEvents = eventArray.length;
        return (numberOfEvents);
    }

    /**
    This function isn't particularly useful. It returns the eveent state prior to the current state.
    Ideally it should return an array of events, but returning dynamic arrays is an experimental feature in Solidity
     */
    function getEventHistoryForTradeItem(uint256 GTIN)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            string memory,
            uint256,
            uint256,
            uint256,
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            string memory
        )
    {
        CommonLibrary.TradeItemEvent[] memory eventArray = tradeItemEvents[GTIN];
        uint256 numberOfEvents = eventArray.length;
        return (this.getTradeItemEventByIndex(GTIN, numberOfEvents - 1));
    }

    /**
    Returns the commissioned event for the token
     */
    function getCommissionedEventForTradeItem(uint256 GTIN)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            string memory,
            uint256,
            uint256,
            uint256,
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            string memory
        )
    {
        return (this.getTradeItemEventByIndex(GTIN, 0));
    }

    /**
    Returns an event by index for a token
     */
    function getTradeItemEventByIndex(uint256 GTIN, uint256 index)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            string memory,
            uint256,
            uint256,
            uint256,
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            string memory
        )
    {
        CommonLibrary.TradeItemEvent[] memory eventArray = tradeItemEvents[GTIN];
        uint256 numberOfEvents = eventArray.length;
        require(numberOfEvents > 0, "No events exist for this trade item");
        return (
            eventArray[index].tokenOwner,
            eventArray[index].LOTID,
            eventArray[index].GTIN,
            eventArray[index].action,
            eventArray[index].eventTimestamp,
            eventArray[index].sourceBizLocationGLN,
            eventArray[index].destinationBizLocationGLN,
            eventArray[index].bizStep,
            eventArray[index].disposition,
            eventArray[index].uom,
            eventArray[index].inputQuantity,
            eventArray[index].outputQuantity,
            eventArray[index].tradeItemSupplementaryInfo
        );
    }
}
