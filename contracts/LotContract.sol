pragma solidity ^0.5.14;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./BizLocationContract.sol";
import "./LotEventContract.sol";
import "./CommonLibrary.sol";

/**
 @title Represents a LOT, which is tracked as an ERC721 token
 @author Michael Edge
*/
contract LotContract is ERC721Full, Ownable {
    // using Counters for Counters.Counter;
    // Counters.Counter private GTINs;

    BizLocationContract bizLocation; // holds the address of the BizLocationContract smart contract. Used to obtain location information
    LotEventContract lotEvent; // holds the address of the LotEventContract smart contract. Used to capture events

    // Store the commissioned TRADEITEM
    CommonLibrary.TradeItem public tradeItem;

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

    constructor() public ERC721Full("TRADEITEM", "TRDI") {}

    // The ERC721 token is minted with a LOTID, which uniquely tracks LOTS
    function mint(address to, uint256 LOTID) public onlyOwner {
        _mint(to, LOTID);
    }

    // Set the address of the BizLocationContract contract so it can be called from this contract
    function setBizLocationAddress(BizLocationContract bizLocationAddress)
        public
    {
        require(
            address(uint160(address(bizLocationAddress))) > address(0),
            "BizLocationContract address must contain a valid value"
        );
        bizLocation = bizLocationAddress;
    }

    // Set the address of the lotEventContract contract so it can be called from this contract
    function setLotEventContractAddress(
        LotEventContract lotEventContractAddress
    ) public {
        require(
            address(uint160(address(lotEventContractAddress))) > address(0),
            "lotEventContract address must contain a valid value"
        );
        lotEvent = lotEventContractAddress;
    }

    /** New TRADEITEMS can only be commissioned (created) at locations that are producers of the raw TRADEITEM
        e.g. a farm produces a crop which is a TRADEITEM. Washing and drying beans is a transformation
        activity on the TRADEITEM and does not result in the ecreation of a new TRADEITEM. It is simply a
        step in the supply chain and is represented in the contract as a tradeItemEvent.

        The commissioned TRADEITEM will be stored as the first TRADEITEM in the array, tradeItemEvents.

        TRADEITEMS are commissioned with a GTIN, Global Trade Item Number, which uniquely tracks trade items
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
            lotEvent.getNumberEventsForTradeItem(GTIN) < 1,
            "A commissioned TRADEITEM can only be commissioned once"
        );
        tradeItem = CommonLibrary.TradeItem(
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
        // store the commissioned event
        lotEvent.captureTradeItemEvent(
            ownerOf(LOTID),
            LOTID,
            GTIN,
            "COMMISSION",
            bizLocationGLN,
            bizLocationGLN,
            bizStep,
            disposition,
            uom,
            quantity,
            quantity,
            ""
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
        // store the transform event
        lotEvent.captureTradeItemEvent(
            ownerOf(getLotForTradeItem(GTIN)),
            getLotForTradeItem(GTIN),
            GTIN,
            "TRANSFORM",
            bizLocationGLN,
            bizLocationGLN,
            bizStep,
            disposition,
            uom,
            inputQuantity,
            outputQuantity,
            ""
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
        // store the observe event
        lotEvent.captureTradeItemEvent(
            ownerOf(getLotForTradeItem(GTIN)),
            getLotForTradeItem(GTIN),
            GTIN,
            "TRANSFORM",
            bizLocationGLN,
            bizLocationGLN,
            bizStep,
            disposition,
            uom,
            quantity,
            quantity,
            tradeItemSupplementaryInfo
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
        uint256 sourceBizLocationGLN,
        uint256 destinationBizLocationGLN,
        string memory bizStep,
        string memory disposition,
        string memory shippingInfo, // example {"SSCC": 12309823478, "bizLocationGLNShipper": 238477723}
        string memory uom,
        uint256 quantity
    ) public {
         // store the observe event
        lotEvent.captureTradeItemEvent(
            ownerOf(getLotForTradeItem(GTIN)),
            getLotForTradeItem(GTIN),
            GTIN,
            "SHIPPING",
            sourceBizLocationGLN,
            destinationBizLocationGLN,
            bizStep,
            disposition,
            uom,
            quantity,
            quantity,
            ""
        );
    }

    /**
    Getters
    */

    /**
    Returns the LOT ID owning a TRADEITEM
     */
    function getLotForTradeItem(uint256 GTIN) public view returns (uint256) {
        return (lotForTradeItem[GTIN]);
    }

    /**
    Returns the TRADEITEM owned by a LOT ID
     */
    function getTradeItemsForLot(uint256 LOTID)
        public
        view
        returns (uint256[] memory)
    {
        return (tradeItemsForLot[LOTID]);
    }
}
