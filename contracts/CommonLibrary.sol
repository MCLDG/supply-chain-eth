pragma solidity ^0.5.14;

/**
 @title Library for common items
 @author Michael Edge
*/
library CommonLibrary {
    // The ERC721 standard recommends storing token metadata off-chain, in storage such as IPFS or similar, and
    // using the metadata extension (via a URI) to retrieve this along with the token. Their justification is that
    // storing on-chain metadata is expensive. For the sake of simplicity I've chosen to store metadata on-chain.

    // The current state of the TRADEITEM is captured in this struct, and the associated mapping below
    struct TradeItem {
        uint256 bizLocationGLN; // bizLocation currently housing the TRADEITEM
        string bizStep; // the EPCIS business step, examples include “commissioning”, “roasting”, “washing”,
        // “inspecting”, “packing”, “picking”, “shipping”, “retail_selling.”
        string disposition; // identifies the business condition subsequent to the event, examples include “active”,
        // “in_progress”, “in_transit”, “expired”, “recalled”, “retail_sold” and “stolen.”
        string uom; //unit of measure, such as KG. If no UOM is specified, it defaults to quantity
        uint256 quantity; // measured in terms of UOM, e.g. 500kg
    }

    // Coffee is transformed as it progresses through the supply chain, from raw beans, to washed, to dried, to roasted, etc.
    // Events that occur during production line processing are captured in this struct, and the associated mapping below.
    // This includes EPCIS events, such as commission, transform, observe
    struct TradeItemEvent {
        address tokenOwner;
        uint256 LOTID;
        uint256 GTIN; // Global Trade Item Number
        string action; // EPCIS event, such as OBSERVE, TRANSFORM, COMMISSION
        uint256 eventTimestamp;
        uint256 sourceBizLocationGLN; // source location, if the event included a transfer from source to destination
        uint256 destinationBizLocationGLN; // destination location, if the event included a transfer from source to destination
        string bizStep;
        string disposition;
        string uom;
        uint256 inputQuantity;
        uint256 outputQuantity;
        string tradeItemSupplementaryInfo; // additional info captured by the event, such as timestamp, sensor data during an OBSERVE event, etc.
    }

    // emitted when an event occurs against a TRADEITEM, for e.g. a TRANSFORM event from coffee beans to ground coffee
    // these events are based on EPCIS events, such as TRANSFORM, OBSERVE, COMMISSION, etc.
    event TradeItemEmitEvent(
        address tokenOwner,
        uint256 LOTID,
        uint256 GTIN,
        string action, // EPCIS event, such as OBSERVE, TRANSFORM, COMMISSION
        uint256 eventTimestamp,
        uint256 sourceBizLocationGLN // source location, if the event included a transfer from source to destination
        // uint256 destinationBizLocationGLN, // destination location, if the event included a transfer from source to destination
        // string bizStep,
        // string disposition,
        // string uom,
        // uint256 inputQuantity,
        // uint256 outputQuantity
    );

    function emitTradeItemEvent(
        address owner,
        uint256 LOTID,
        uint256 GTIN,
        string memory action,
        uint256 eventTimestamp,
        uint256 sourceBizLocationGLN
        // uint256 destinationBizLocationGLN,
        // string memory bizStep,
        // string memory disposition,
        // string memory uom,
        // uint256 inputQuantity,
        // uint256 outputQuantity
    ) public {
        emit TradeItemEmitEvent(
            owner,
            LOTID,
            GTIN,
            action,
            eventTimestamp,
            sourceBizLocationGLN
            // destinationBizLocationGLN,
            // bizStep,
            // disposition,
            // uom,
            // inputQuantity,
            // outputQuantity
        );
    }
}
