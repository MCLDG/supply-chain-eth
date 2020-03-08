pragma solidity ^0.5.14;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./BusinessLocation.sol";

contract MicrobatchToken is ERC721Full, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    BusinessLocation businessLocation;

    // emitted when an asset is associated with the token
    event TokenAssetAssociationEvent(
        address tokenOwner,
        uint256 tokenId,
        uint256 businessLocationId,
        string bizStep,
        string uom,
        uint256 quantity
    );

    // emitted when an event occurs against an asset, for e.g. a TRANSFORM event from coffee beans to ground coffee
    // these events are based on EPCIS events, such as TRANSFORM, OBSERVE, COMMISSION, etc.
    event TokenAssetEvent(
        address tokenOwner,
        uint256 tokenId,
        string action, // EPCIS event, such as OBSERVE, TRANSFORM
        string bizStep, // the event, such as SHIPPED
        uint256 bizLocation,
        uint256 inputQuantity,
        uint256 outputQuantity,
        uint eventTime
    );

    // The ERC721 standard recommends storing token metadata off-chain, in storage such as IPFS or similar, and
    // using the metadata extension (via a URI) to retrieve this along with the token. Their justification is that
    // storing on-chain metadata is expensive. For the sake of simplicity I've chosen to store metadata on-chain.

    // The current state of the asset is captured in this struct, and the associated mapping below
    struct Asset {
        uint256 businessLocationId; // businessLocation currently housing the asset
        string bizStep; // step asset is currently in, such as wash, dry, roast
        string uom; //unit of measure, such as KG
        uint256 quantity; // measured in terms of UOM, e.g. 500kg
    }

    // Mapping from token ID to asset represented by the token
    mapping(uint256 => Asset) private tokenAssets;

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

    function setBusinessLocationAddress(BusinessLocation businessLocationAddress) public {
        require(
            address(uint160(address(businessLocationAddress))) > address(0),
            "BusinessLocation address must contain a valid value"
        );
        businessLocation = businessLocationAddress;
    }

    /**
    An asset is transformed when it changes from one form to another, for example, from dried coffee beans to ground coffee.
    The transformation is captured for a particular token as follows:
        - the pre-transformation state of the asset is pushed to the end of the AssetTransformation array
        - the post-transformation state of the asset is updated in tokenAssets
    */
    function transformAsset(
        uint256 tokenId,
        uint256 businessLocationId,
        uint256 inputQuantity,
        uint256 outputQuantity,
        string memory bizStep,
        string memory uom
    ) public {
        Asset storage postTransformAsset = tokenAssets[tokenId];
        // store the pre-transformation state of the asset
        Asset memory preTransformAsset = Asset(
            postTransformAsset.businessLocationId,
            postTransformAsset.bizStep,
            postTransformAsset.uom,
            postTransformAsset.quantity
        );
        // push the pre-transformation state of the asset to the transform array
        AssetTransformation[] storage transformArray = tokenAssetTransformations[tokenId];
        AssetTransformation memory transform = AssetTransformation(
            block.timestamp,
            preTransformAsset
        );
        // update the current state of the asset to the post-transformation state
        uint numberOfTransforms = transformArray.push(transform);
        postTransformAsset.businessLocationId = businessLocationId;
        postTransformAsset.bizStep = bizStep;
        postTransformAsset.uom = uom;
        postTransformAsset.quantity = outputQuantity;
        emit TokenAssetEvent(
            ownerOf(tokenId),
            tokenId,
            "TRANSFORM",
            bizStep,
            businessLocationId,
            inputQuantity,
            outputQuantity,
            block.timestamp
        );
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
            string memory,
            uint256,
            uint256
        )
    {
        AssetTransformation[] memory transformArray = tokenAssetTransformations[tokenId];
        uint numberOfTransforms = transformArray.length;
        return (
            tokenId,
            transformArray[numberOfTransforms - 1].asset.businessLocationId,
            transformArray[numberOfTransforms - 1].asset.bizStep,
            transformArray[numberOfTransforms - 1].asset.quantity,
            transformArray[numberOfTransforms - 1].timestamp
        );
    }

    /** New assets can only be created by facilities that are producers of the raw asset
        e.g. a farm produces a crop which is an asset. Washing and drying beans is a transformation
        activity on the asset and does not result in the ecreation of a new asset. It is simply a
        step in the supply chain and is represented in the contract as an AssetTransformation
    */
    function setTokenAsset(
        uint256 tokenId,
        uint256 businessLocationId,
        string memory bizStep,
        string memory uom,
        uint256 quantity
    ) public {
        (, , , bool assetCommission, ) = businessLocation.get(businessLocationId);
        require(
            assetCommission == true,
            "Assets can only be created at facilities that produce/commission raw assets"
        );
        tokenAssets[tokenId] = Asset(
            businessLocationId,
            bizStep,
            uom,
            quantity
        );
        emit TokenAssetAssociationEvent(
            ownerOf(tokenId),
            tokenId,
            businessLocationId,
            bizStep,
            uom,
            quantity
        );
    }

    function getTokenAsset(uint256 tokenId)
        public
        view
        returns (
            uint256,
            uint256,
            string memory,
            string memory,
            uint256
        )
    {
        return (
            tokenId,
            tokenAssets[tokenId].businessLocationId,
            tokenAssets[tokenId].bizStep,
            tokenAssets[tokenId].uom,
            tokenAssets[tokenId].quantity
        );
    }
}
