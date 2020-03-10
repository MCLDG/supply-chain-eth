pragma solidity ^0.5.14;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./BizLocation.sol";

contract MicrobatchToken is ERC721Full, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    BizLocation bizLocation;

    // emitted when an event occurs against an asset, for e.g. a TRANSFORM event from coffee beans to ground coffee
    // these events are based on EPCIS events, such as TRANSFORM, OBSERVE, COMMISSION, etc.
    event TokenAssetEvent(
        address tokenOwner,
        uint256 tokenId,
        string action, // EPCIS event, such as OBSERVE, TRANSFORM, COMMISSION
        string bizStep, // the event, such as SHIPPED
        uint256 bizLocationId,
        uint256 inputQuantity,
        uint256 outputQuantity
    );

    // The ERC721 standard recommends storing token metadata off-chain, in storage such as IPFS or similar, and
    // using the metadata extension (via a URI) to retrieve this along with the token. Their justification is that
    // storing on-chain metadata is expensive. For the sake of simplicity I've chosen to store metadata on-chain.

    // The current state of the asset is captured in this struct, and the associated mapping below
    struct Asset {
        uint256 bizLocationId; // bizLocation currently housing the asset
        string bizStep; // step asset is currently in, such as wash, dry, roast
        string uom; //unit of measure, such as KG
        uint256 quantity; // measured in terms of UOM, e.g. 500kg
    }

    // Coffee is transformed as it progresses through the supply chain, from raw beans, to washed, to dried, to roasted, etc.
    // Events that occur during production line processing are captured in this struct, and the associated mapping below.
    // This includes EPCIS events, such as commission, transform, observe
    struct AssetEvent {
        uint256 timestamp; // when the event took place
        string assetSupplementaryInfo; // additional info captured by the event, such as sensor data during an OBSERVE event
        Asset asset; // the asset state at the time of the event
    }

    // Mapping from token ID to the array of asset events
    mapping(uint256 => AssetEvent[]) private tokenAssetEvents;

    constructor() public ERC721Full("MICROBATCH", "MBAT") {}

    // function mint(address to, uint256 tokenId) public onlyOwner {
    //     _mint(to, tokenId);
    // }
    function _mint(address to) public onlyOwner {
        tokenIds.increment();
        uint256 newItemId = tokenIds.current();
        _mint(to, newItemId);
    }

    // Set the address of the BizLocation contract so it can be called from this contract
    function setBizLocationAddress(BizLocation bizLocationAddress) public {
        require(
            address(uint160(address(bizLocationAddress))) > address(0),
            "BizLocation address must contain a valid value"
        );
        bizLocation = bizLocationAddress;
    }

    /** New assets can only be commissioned (created) at facilities that are producers of the raw asset
        e.g. a farm produces a crop which is an asset. Washing and drying beans is a transformation
        activity on the asset and does not result in the ecreation of a new asset. It is simply a
        step in the supply chain and is represented in the contract as an AssetEvent.

        The commissioned asset will be stored as the first asset in the array, tokenAssetEvents
    */
    function commissionAsset(
        uint256 tokenId,
        uint256 bizLocationId,
        string memory bizStep,
        string memory uom,
        uint256 quantity
    ) public {
        (, , , bool assetCommission, ) = bizLocation.get(bizLocationId);
        require(
            assetCommission == true,
            "Assets can only be created at facilities that produce/commission raw assets"
        );
        require(
            this.getNumberEventsForTokenAsset(tokenId) < 1,
            "This tokenId contains a commissioned asset. Assets can be commissioned once"
        );
        Asset memory asset = Asset(bizLocationId, bizStep, uom, quantity);
        // push the commissioned asset as the first element in the transform array
        AssetEvent[] storage eventArray = tokenAssetEvents[tokenId];
        AssetEvent memory assetEvent = AssetEvent(block.timestamp, "", asset);
        eventArray.push(assetEvent);
        // emit the event
        emit TokenAssetEvent(
            ownerOf(tokenId),
            tokenId,
            "COMMISSION",
            bizStep,
            bizLocationId,
            quantity,
            quantity
        );
    }

    /**
    An asset is transformed when it changes from one form to another, for example, from dried coffee beans to ground coffee.
    The transformation is captured for a particular token by pushing the post-transformation state of the asset
    to the end of the AssetEvent array. The pre-transformation state of the asset already exists in the
    AssetEvent array. It was pushed there either by the commissionAsset function, or a previous transformAsset.
    */
    function transformAsset(
        uint256 tokenId,
        uint256 bizLocationId,
        string memory bizStep,
        string memory uom,
        uint256 inputQuantity,
        uint256 outputQuantity
    ) public {
        Asset memory asset = Asset(bizLocationId, bizStep, uom, outputQuantity);
        // push the post-transformation state of the asset to the transform array
        AssetEvent[] storage eventArray = tokenAssetEvents[tokenId];
        AssetEvent memory assetEvent = AssetEvent(block.timestamp, "", asset);
        eventArray.push(assetEvent);
        // emit the event
        emit TokenAssetEvent(
            ownerOf(tokenId),
            tokenId,
            "TRANSFORM",
            bizStep,
            bizLocationId,
            inputQuantity,
            outputQuantity
        );
    }

    /**
    Observe an asset. Assets are observed  transformed when it changes from one form to another, for example, from dried coffee beans to ground coffee.
    The transformation is captured for a particular token by pushing the post-transformation state of the asset
    to the end of the AssetEvent array. The pre-transformation state of the asset already exists in the
    AssetEvent array. It was pushed there either by the commissionAsset function, or a previous transformAsset.
    */
    function observeAsset(
        uint256 tokenId,
        uint256 bizLocationId,
        string memory bizStep,
        string memory uom,
        uint256 quantity,
        string memory assetSupplementaryInfo
    ) public {
        Asset memory asset = Asset(bizLocationId, bizStep, uom, quantity);
        // push the observed state of the asset to the transform array
        AssetEvent[] storage eventArray = tokenAssetEvents[tokenId];
        AssetEvent memory assetEvent = AssetEvent(
            block.timestamp,
            assetSupplementaryInfo,
            asset
        );
        eventArray.push(assetEvent);
        // emit the event
        emit TokenAssetEvent(
            ownerOf(tokenId),
            tokenId,
            "OBSERVE",
            bizStep,
            bizLocationId,
            quantity,
            quantity
        );
    }

    /**
    Getters
    */

    /**
    Return the number of events that have occurred against an asset (i.e. commission, transform, observe, etc.)
    */
    function getNumberEventsForTokenAsset(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        AssetEvent[] memory eventArray = tokenAssetEvents[tokenId];
        uint256 numberOfEvents = eventArray.length;
        return (numberOfEvents);
    }

    /**
    This function isn't particularly useful. It returns the asset state prior to the current state.
    Ideally it should return an array of transforms, but returning dynamic arrays is an experimental feature only
     */
    function getEventHistory(uint256 tokenId)
        public
        view
        returns (
            uint256,
            uint256,
            string memory,
            uint256,
            string memory,
            string memory,
            uint256
        )
    {
        AssetEvent[] memory eventArray = tokenAssetEvents[tokenId];
        uint256 numberOfEvents = eventArray.length;
        return (this.getAssetEventByIndex(tokenId, numberOfEvents - 1));
    }

    /**
    Returns the commissioned asset
     */
    function getCommissionedAsset(uint256 tokenId)
        public
        view
        returns (
            uint256,
            uint256,
            string memory,
            uint256,
            string memory,
            string memory,
            uint256
        )
    {
        return (this.getAssetEventByIndex(tokenId, 0));
    }

    /**
    Returns an asset event by index for a token
     */
    function getAssetEventByIndex(uint256 tokenId, uint256 index)
        public
        view
        returns (
            uint256,
            uint256,
            string memory,
            uint256,
            string memory,
            string memory,
            uint256
        )
    {
        AssetEvent[] memory eventArray = tokenAssetEvents[tokenId];
        uint256 numberOfEvents = eventArray.length;
        require(numberOfEvents > 0, "No assets exist for this token");
        return (
            tokenId,
            eventArray[index].timestamp,
            eventArray[index].assetSupplementaryInfo,
            eventArray[index].asset.bizLocationId,
            eventArray[index].asset.bizStep,
            eventArray[index].asset.uom,
            eventArray[index].asset.quantity
        );
    }

}
