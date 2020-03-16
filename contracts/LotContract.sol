pragma solidity ^0.5.14;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./BizLocationContract.sol";

/**
 @title Represents a LOT, which is tracked as an ERC721 token
 @author Michael Edge
*/
 contract LotContract is ERC721Full, Ownable {
    // using Counters for Counters.Counter;
    // Counters.Counter private GTINs;

    BizLocationContract bizLocation; // holds the address of the BizLocationContract smart contract. Used to obtain location information

    // emitted when an event occurs against a TRADEITEM, for e.g. a TRANSFORM event from coffee beans to ground coffee
    // these events are based on EPCIS events, such as TRANSFORM, OBSERVE, COMMISSION, etc.
    event TradeItemEmitEvent(
        address tokenOwner,
        uint256 GTIN,
        string action, // EPCIS event, such as OBSERVE, TRANSFORM, COMMISSION
        string bizStep, // the EPCIS business step, examples include “commissioning”, “roasting”, “washing”, “inspecting”, “packing”, “picking”, “shipping”, “retail_selling.”
        uint256 bizLocationGLN,
        uint256 inputQuantity,
        uint256 outputQuantity
    );

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
        string action; // EPCIS event, such as OBSERVE, TRANSFORM, COMMISSION
        uint256 eventTimestamp;
        uint256 sourceBizLocationGLN; // source location, if the event included a transfer from source to destination
        uint256 destinationBizLocationGLN; // destination location, if the event included a transfer from source to destination
        string tradeItemSupplementaryInfo; // additional info captured by the event, such as timestamp, sensor data during an OBSERVE event, etc.
        TradeItem tradeItem; // the TRADEITEM state at the time of the event
    }

    // Mapping from the LOT ID to the array of TRADEITEM IDs (GTIN)
    // You can query tradeItemEvents using the GTIN to see details of the TRADEITEM
    // In the case of a coffee LOT (i.e. a batch of raw coffee beans), this is 1:1.
    // I.e. one LOT == 1 TRADEITEM, which represents the batch of raw coffee as harvested by the farmer
    // In the case of packaged coffee in units of 500g or 1kg, this is 1:M.
    // I.e. one LOT = many TRADEITEMS, where each TRADEITEM represents 1 package of coffee for resale
    mapping(uint256 => uint256[]) private tradeItemsForLot;

    // Mapping from the TRADEITEM to the associated LOT ID
    // The reverse of the above map, to discover the LOT that owns a TRADEITEM
    mapping(uint256 => uint256) private lotForTradeItem;

    // Mapping from GTIN (representing the TRADEITEM) to the array of TRADEITEM events.
    // Current state of the trade item can be obtain from the array
    mapping(uint256 => TradeItemEvent[]) private tradeItemEvents;

    constructor() public ERC721Full("TRADEITEM", "TRDI") {}

    // The ERC721 token is minted with a GTIN, Global Trade Item Number, which uniquely tracks trade items
    function mint(address to, uint256 LOTID) public onlyOwner {
        _mint(to, LOTID);
    }

    // Set the address of the BizLocationContract contract so it can be called from this contract
    function setBizLocationAddress(BizLocationContract bizLocationAddress) public {
        require(
            address(uint160(address(bizLocationAddress))) > address(0),
            "BizLocationContract address must contain a valid value"
        );
        bizLocation = bizLocationAddress;
    }

    /** New TRADEITEMS can only be commissioned (created) at locations that are producers of the raw TRADEITEM
        e.g. a farm produces a crop which is a TRADEITEM. Washing and drying beans is a transformation
        activity on the TRADEITEM and does not result in the ecreation of a new TRADEITEM. It is simply a
        step in the supply chain and is represented in the contract as a tradeItemEvent.

        The commissioned TRADEITEM will be stored as the first TRADEITEM in the array, tradeItemEvents
    */
    function commissionTradeItem(
        uint256 LOTID,
        uint256 GTIN,
        uint256 bizLocationGLN,
        string memory bizStep,
        string memory disposition,
        string memory uom,
        uint256 quantity
    ) public {
        (, , , bool tradeItemCommission, ) = bizLocation.get(bizLocationGLN);
        require(
            tradeItemCommission == true,
            "tradeItems can only be created at locations that produce raw tradeItems"
        );
        require(
            this.getNumberEventsForTradeItem(GTIN) < 1,
            "A commissioned TRADEITEM can only be commissioned once"
        );
        TradeItem memory tradeItem = TradeItem(
            bizLocationGLN,
            bizStep,
            disposition,
            uom,
            quantity
        );
        // store the GTIN as owned by the LOT
        uint256[] storage tradeItemArray = tradeItemsForLot[LOTID];
        tradeItemArray.push(GTIN);
        // store the LOT this TRADEITEM belongs to
        lotForTradeItem[GTIN] = LOTID;
        // push the commissioned TRADEITEM event as the first element in the events array
        TradeItemEvent[] storage eventArray = tradeItemEvents[GTIN];
        TradeItemEvent memory tradeItemEvent = TradeItemEvent(
            "COMMISSION",
            block.timestamp,
            bizLocationGLN,
            bizLocationGLN,
            "",
            tradeItem
        );
        eventArray.push(tradeItemEvent);
        // emit the event
        emit TradeItemEmitEvent(
            ownerOf(LOTID),
            GTIN,
            "COMMISSION",
            bizStep,
            bizLocationGLN,
            quantity,
            quantity
        );
    }

    /**
    a TRADEITEM is transformed when it changes from one form to another, for example, from dried coffee beans to ground coffee.
    The transformation is captured for a particular token by pushing the post-transformation state of the TRADEITEM
    to the end of the TradeItemEvent array. The pre-transformation state of the TRADEITEM already exists in the
    TradeItemEvent array. It was pushed there either by the commissionTradeItem function, or a previous transformtradeItem.
    */
    function transformTradeItem(
        uint256 GTIN,
        uint256 bizLocationGLN,
        string memory bizStep,
        string memory disposition,
        string memory uom,
        uint256 inputQuantity,
        uint256 outputQuantity
    ) public {
        TradeItem memory tradeItem = TradeItem(
            bizLocationGLN,
            bizStep,
            disposition,
            uom,
            outputQuantity
        );
        // push the post-transformation state of the TRADEITEM to the events array
        TradeItemEvent[] storage eventArray = tradeItemEvents[GTIN];
        TradeItemEvent memory tradeItemEvent = TradeItemEvent(
            "TRANSFORM",
            block.timestamp,
            bizLocationGLN,
            bizLocationGLN,
            "",
            tradeItem
        );
        eventArray.push(tradeItemEvent);
        // emit the event
        emit TradeItemEmitEvent(
            ownerOf(getLotForTradeItem(GTIN)),
            GTIN,
            "TRANSFORM",
            bizStep,
            bizLocationGLN,
            inputQuantity,
            outputQuantity
        );
    }

    /**
    Observe a TRADEITEM. tradeItems are observed  transformed when it changes from one form to another, for example, from dried coffee beans to ground coffee.
    The transformation is captured for a particular token by pushing the post-transformation state of the TRADEITEM
    to the end of the TradeItemEvent array. The pre-transformation state of the TRADEITEM already exists in the
    TradeItemEvent array. It was pushed there either by the commissionTradeItem function, or a previous transformtradeItem.
    */
    function observeTradeItem(
        uint256 GTIN,
        uint256 bizLocationGLN,
        string memory bizStep,
        string memory disposition,
        string memory uom,
        uint256 quantity,
        string memory tradeItemSupplementaryInfo
    ) public {
        TradeItem memory tradeItem = TradeItem(
            bizLocationGLN,
            bizStep,
            disposition,
            uom,
            quantity
        );
        // push the observed state of the TRADEITEM to the events array
        TradeItemEvent[] storage eventArray = tradeItemEvents[GTIN];
        TradeItemEvent memory tradeItemEvent = TradeItemEvent(
            "OBSERVE",
            block.timestamp,
            bizLocationGLN,
            bizLocationGLN,
            tradeItemSupplementaryInfo,
            tradeItem
        );
        eventArray.push(tradeItemEvent);
        // emit the event
        emit TradeItemEmitEvent(
            ownerOf(getLotForTradeItem(GTIN)),
            GTIN,
            "OBSERVE",
            bizStep,
            bizLocationGLN,
            quantity,
            quantity
        );
    }

    /**
    a TRADEITEM is transported from one location to another, for example, from farmer to dryer/washer.
    During transport, the TRADEITEM is wrapped in a GS1 Logistics Unit, which facilitates tracing the TRADEITEM from
    one location to another, and allows us to capture metadata against it (such as source/destination location).
    
    Ownership may change when a TRADEITEM is transported between locations.
    */
    function transportTradeItem(
        uint256 GTIN,
        uint256 bizLocationGLNFrom,
        uint256 bizLocationGLNTo,
        string memory shippingInfo, // example {"SSCC": 12309823478, "bizLocationGLNShipper": 238477723}
        string memory uom,
        uint256 quantity
    ) public {
        // TradeItem memory tradeItem = TradeItem(
        //     bizLocationGLNTo,
        //     "SHIPPING",
        //     "IN-TRANSIT",
        //     uom,
        //     quantity
        // );
    //     // push the post-transformation state of the TRADEITEM to the events array        
        TradeItemEvent[] storage eventArray = tradeItemEvents[GTIN];
        uint256 numberEvents = getNumberEventsForTradeItem(GTIN);
        TradeItem memory tradeItem = eventArray[numberEvents - 1].tradeItem;
        TradeItemEvent memory tradeItemEvent = TradeItemEvent(
            "AGGREGATION",
            block.timestamp,
            bizLocationGLNFrom,
            bizLocationGLNTo,
            shippingInfo,
            tradeItem
        );
         eventArray.push(tradeItemEvent);
    //     // emit the event
        emit TradeItemEmitEvent(
            ownerOf(getLotForTradeItem(GTIN)),
            GTIN,
            "TRANSFORM",
            "SHIPPING",
            bizLocationGLNTo,
            quantity,
            quantity
        );
    }

    /**
    Getters
    */

    /**
    Returns the LOT ID owning a TRADEITEM
     */
    function getLotForTradeItem(uint256 GTIN)
        public
        view
        returns (
            uint256
        )
    {
        return (lotForTradeItem[GTIN]);
    }

    /**
    Returns the TRADEITEM owned by a LOT ID
     */
    function getTradeItemsForLot(uint256 LOTID)
        public
        view
        returns (
            uint256[] memory
        )
    {
        return (tradeItemsForLot[LOTID]);
    }

    /**
    Return the number of events that have occurred against a TRADEITEM (i.e. commission, transform, observe, etc.)
    */
    function getNumberEventsForTradeItem(uint256 GTIN)
        public
        view
        returns (uint256)
    {
        TradeItemEvent[] memory eventArray = tradeItemEvents[GTIN];
        uint256 numberOfEvents = eventArray.length;
        return (numberOfEvents);
    }

    /**
    This function isn't particularly useful. It returns the TRADEITEM state prior to the current state.
    Ideally it should return an array of events, but returning dynamic arrays is an experimental feature only
     */
    function getEventHistory(uint256 GTIN)
        public
        view
        returns (
            uint256,
            string memory,
            uint256,
            string memory,
            string memory,
            uint256
        )
    {
        TradeItemEvent[] memory eventArray = tradeItemEvents[GTIN];
        uint256 numberOfEvents = eventArray.length;
        return (this.getTradeItemEventByIndex(GTIN, numberOfEvents - 1));
    }

    /**
    Returns the commissioned TRADEITEM
     */
    function getCommissionedTradeItem(uint256 GTIN)
        public
        view
        returns (
            uint256,
            string memory,
            uint256,
            string memory,
            string memory,
            uint256
        )
    {
        return (this.getTradeItemEventByIndex(GTIN, 0));
    }

    /**
    Returns a TRADEITEM event by index for a token
     */
    function getTradeItemEventByIndex(uint256 GTIN, uint256 index)
        public
        view
        returns (
            uint256,
            string memory,
            uint256,
            string memory,
            string memory,
            uint256
        )
    {
        TradeItemEvent[] memory eventArray = tradeItemEvents[GTIN];
        uint256 numberOfEvents = eventArray.length;
        require(numberOfEvents > 0, "No tradeItems exist for this token");
        return (
            GTIN,
            eventArray[index].tradeItemSupplementaryInfo,
            eventArray[index].tradeItem.bizLocationGLN,
            eventArray[index].tradeItem.bizStep,
            eventArray[index].tradeItem.uom,
            eventArray[index].tradeItem.quantity
        );
    }

}
