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
    // the production line processing is captured in this struct, and the associated mapping below
    struct AssetTransformation {
        uint256 timestamp; // when the transformation took place
        Asset asset; // the asset prior to the transformation
    }

    // Mapping from token ID to the array of transformations the asset has undergone since being commissioned
    mapping(uint256 => AssetTransformation[]) private tokenAssetTransformations;

    constructor() public ERC721Full("MICROBATCH", "MBAT") {}

    // function mint(address to, uint256 tokenId) public onlyOwner {
    //     _mint(to, tokenId);
    // }
    function _mint(address to) public onlyOwner {
        tokenIds.increment();
        uint256 newItemId = tokenIds.current();
        _mint(to, newItemId);
    }

    // Can this be removed?
    // Location applies to the facilities, not the asset itself
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
        step in the supply chain and is represented in the contract as an AssetTransformation.

        The commissioned asset will be stored as the first asset in the array, tokenAssetTransformations
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
            this.getNumberTransformsForTokenAsset(tokenId) < 1,
            "This tokenId contains a commissioned asset. Assets can be commissioned once"
        );
        Asset memory asset = Asset(
            bizLocationId,
            bizStep,
            uom,
            quantity
        );
        // push the commissioned asset as the first element in the transform array
        AssetTransformation[] storage transformArray = tokenAssetTransformations[tokenId];
        AssetTransformation memory transform = AssetTransformation(
            block.timestamp,
            asset
        );
        // update the current state of the asset to the post-transformation state
        transformArray.push(transform);
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
    to the end of the AssetTransformation array. The pre-transformation state of the asset already exists in the
    AssetTransformation array. It was pushed there either by the commissionAsset function, or a previous transformAsset.
    */
    function transformAsset(
        uint256 tokenId,
        uint256 bizLocationId,
        string memory bizStep,
        string memory uom,
        uint256 inputQuantity,
        uint256 outputQuantity
    ) public {
        Asset memory asset = Asset(
            bizLocationId,
            bizStep,
            uom,
            outputQuantity
        );
        // push the pre-transformation state of the asset to the transform array
        AssetTransformation[] storage transformArray = tokenAssetTransformations[tokenId];
        AssetTransformation memory transform = AssetTransformation(
            block.timestamp,
            asset
        );
        // update the current state of the asset to the post-transformation state
        transformArray.push(transform);
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

    function getNumberTransformsForTokenAsset(uint256 tokenId)
        public
        view
        returns (
            uint256
        )
    {
        AssetTransformation[] memory transformArray = tokenAssetTransformations[tokenId];
        uint numberOfTransforms = transformArray.length;
        return (numberOfTransforms);
    }

    /**
    This function isn't particularly useful. It returns the asset state prior to the current state.
    Ideally it should return an array of transforms, but returning dynamic arrays is an experimental feature only
     */
    function getTransformHistory(uint256 tokenId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            string memory,
            string memory,
            uint256
        )
    {
        AssetTransformation[] memory transformArray = tokenAssetTransformations[tokenId];
        uint numberOfTransforms = transformArray.length;
        return (this.getAssetByIndex(tokenId, numberOfTransforms - 1));
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
            uint256,
            string memory,
            string memory,
            uint256
        )
    {
        return (this.getAssetByIndex(tokenId, 0));
    }

    /**
    Returns an asset by index for a token
     */
    function getAssetByIndex(uint256 tokenId, uint256 index)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            string memory,
            string memory,
            uint256
        )
    {
        AssetTransformation[] memory transformArray = tokenAssetTransformations[tokenId];
        uint numberOfTransforms = transformArray.length;
        require(
            numberOfTransforms > 0,
            "No assets exist for this token"
        );
        return (
            tokenId,
            transformArray[index].timestamp,
            transformArray[index].asset.bizLocationId,
            transformArray[index].asset.bizStep,
            transformArray[index].asset.uom,
            transformArray[index].asset.quantity
        );
    }

}
