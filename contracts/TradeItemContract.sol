pragma solidity ^0.5.14;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./BizLocationContract.sol";

contract TradeItemContract is ERC721Full, Ownable {
    // using Counters for Counters.Counter;
    // Counters.Counter private GTINs;

    BizLocationContract bizLocation; // holds the address of the BizLocationContract smart contract. Used to obtain location information

    // emitted when an event occurs against a tradeItem, for e.g. a TRANSFORM event from coffee beans to ground coffee
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

    // The current state of the tradeItem is captured in this struct, and the associated mapping below
    struct TradeItem {
        uint256 bizLocationGLN; // bizLocation currently housing the tradeItem
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
        TradeItem tradeItem; // the tradeItem state at the time of the event
    }

    // Mapping from GTIN to the array of tradeItem events. Current state of the trade item can be obtain from the array
    mapping(uint256 => TradeItemEvent[]) private tradeItemEvents;

    constructor() public ERC721Full("TRADEITEM", "TRDI") {}

    // The ERC721 token is minted with a GTIN, Global Trade Item Number, which uniquely tracks trade items
    function mint(address to, uint256 GTIN) public onlyOwner {
        _mint(to, GTIN);
    }

    // Set the address of the BizLocationContract contract so it can be called from this contract
    function setBizLocationAddress(BizLocationContract bizLocationAddress) public {
        require(
            address(uint160(address(bizLocationAddress))) > address(0),
            "BizLocationContract address must contain a valid value"
        );
        bizLocation = bizLocationAddress;
    }

    /** New tradeItems can only be commissioned (created) at facilities that are producers of the raw tradeItem
        e.g. a farm produces a crop which is a tradeItem. Washing and drying beans is a transformation
        activity on the tradeItem and does not result in the ecreation of a new tradeItem. It is simply a
        step in the supply chain and is represented in the contract as a tradeItemEvent.

        The commissioned tradeItem will be stored as the first tradeItem in the array, tradeItemEvents
    */
    function commissionTradeItem(
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
            "tradeItems can only be created at facilities that produce raw tradeItems"
        );
        require(
            this.getNumberEventsForTradeItem(GTIN) < 1,
            "A commissioned tradeItem can only be commissioned once"
        );
        TradeItem memory tradeItem = TradeItem(
            bizLocationGLN,
            bizStep,
            disposition,
            uom,
            quantity
        );
        // push the commissioned tradeItem as the first element in the transform array
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
            ownerOf(GTIN),
            GTIN,
            "COMMISSION",
            bizStep,
            bizLocationGLN,
            quantity,
            quantity
        );
    }

    /**
    a tradeItem is transformed when it changes from one form to another, for example, from dried coffee beans to ground coffee.
    The transformation is captured for a particular token by pushing the post-transformation state of the tradeItem
    to the end of the TradeItemEvent array. The pre-transformation state of the tradeItem already exists in the
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
        // push the post-transformation state of the tradeItem to the transform array
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
            ownerOf(GTIN),
            GTIN,
            "TRANSFORM",
            bizStep,
            bizLocationGLN,
            inputQuantity,
            outputQuantity
        );
    }

    /**
    Observe a tradeItem. tradeItems are observed  transformed when it changes from one form to another, for example, from dried coffee beans to ground coffee.
    The transformation is captured for a particular token by pushing the post-transformation state of the tradeItem
    to the end of the TradeItemEvent array. The pre-transformation state of the tradeItem already exists in the
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
        // push the observed state of the tradeItem to the transform array
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
            ownerOf(GTIN),
            GTIN,
            "OBSERVE",
            bizStep,
            bizLocationGLN,
            quantity,
            quantity
        );
    }

    /**
    Getters
    */

    /**
    Return the number of events that have occurred against a tradeItem (i.e. commission, transform, observe, etc.)
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
    This function isn't particularly useful. It returns the tradeItem state prior to the current state.
    Ideally it should return an array of transforms, but returning dynamic arrays is an experimental feature only
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
    Returns the commissioned tradeItem
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
    Returns a tradeItem event by index for a token
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
