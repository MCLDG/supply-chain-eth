pragma solidity ^0.5.14;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Facility.sol";

contract MicrobatchToken is ERC721Full, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    Facility facility;

    // emitted when an asset is associated with the token
    event TokenAssetEvent(
        address tokenOwner,
        uint256 tokenId,
        uint256 facilityId,
        string assetState,
        string assetProcess,
        string assetUOM,
        uint256 assetQuantity
    );

    // emitted when an asset is transformed, for e.g. from coffee beans to ground coffee
    event TokenAssetTransformEvent(
        address tokenOwner,
        uint256 tokenId,
        uint256 facilityFromId,
        uint256 facilityToId,
        string assetFromState,
        string assetToState,
        string assetFromProcess,
        string assetToProcess,
        uint256 assetFromQuantity,
        uint256 assetToQuantity,
        uint transformTimestamp
    );

    // The ERC721 standard recommends storing token metadata off-chain, in storage such as IPFS or similar, and
    // using the metadata extension (via a URI) to retrieve this along with the token. Their justification is that
    // storing on-chain metadata is expensive. For the sake of simplicity I've chosen to store metadata on-chain.

    // The current state of the asset is captured in this struct, and the associated mapping below
    struct Asset {
        uint256 facilityId; // facility currently housing the asset
        string assetState; // state asset is currently in, such as raw, finished
        string assetProcess; // step asset is currently in, such as wash, dry, roast
        string assetUOM; //unit of measure, such as KG
        uint256 assetQuantity; // measured in terms of UOM, e.g. 500kg
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

    function setFacilityAddress(Facility facilityAddress) public {
        require(
            address(uint160(address(facilityAddress))) > address(0),
            "Facility address must contain a valid value when calling setFacilityAddress"
        );
        facility = facilityAddress;
    }

    /**
    An asset is transformed when it changes from one form to another, for example, from dried coffee beans to ground coffee.
    The transformation is captured for a particular token as follows:
        - the pre-transformation state of the asset is pushed to the end of the AssetTransformation array
        - the post-transformation state of the asset is updated in tokenAssets
    */
    function transformTokenAsset(
        uint256 tokenId,
        uint256 facilityId,
        string memory assetState,
        string memory assetProcess,
        string memory assetUOM,
        uint256 assetQuantity
    ) public {
        Asset storage postTransformAsset = tokenAssets[tokenId];
        // store the pre-transformation state of the asset
        Asset memory preTransformAsset = Asset(
            postTransformAsset.facilityId,
            postTransformAsset.assetState,
            postTransformAsset.assetProcess,
            postTransformAsset.assetUOM,
            postTransformAsset.assetQuantity
        );
        // push the pre-transformation state of the asset to the transform array
        AssetTransformation[] storage transformArray = tokenAssetTransformations[tokenId];
        AssetTransformation memory transform = AssetTransformation(
            block.timestamp,
            preTransformAsset
        );
        // update the current state of the asset to the post-transformation state
        uint numberOfTransforms = transformArray.push(transform);
        postTransformAsset.facilityId = facilityId;
        postTransformAsset.assetState = assetState;
        postTransformAsset.assetProcess = assetProcess;
        postTransformAsset.assetUOM = assetUOM;
        postTransformAsset.assetQuantity = assetQuantity;
        emit TokenAssetTransformEvent(
            ownerOf(tokenId),
            tokenId,
            transformArray[numberOfTransforms - 1].asset.facilityId,
            numberOfTransforms > 1 ? transformArray[numberOfTransforms - 2].asset.facilityId : 0,
            transformArray[numberOfTransforms - 1].asset.assetState,
            numberOfTransforms > 1 ? transformArray[numberOfTransforms - 2].asset.assetState : "",
            transformArray[numberOfTransforms - 1].asset.assetProcess,
            numberOfTransforms > 1 ? transformArray[numberOfTransforms - 2].asset.assetProcess : "",
            transformArray[numberOfTransforms - 1].asset.assetQuantity,
            numberOfTransforms > 1 ? transformArray[numberOfTransforms - 2].asset.assetQuantity : 0,
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
            string memory,
            uint256,
            uint256
        )
    {
        AssetTransformation[] memory transformArray = tokenAssetTransformations[tokenId];
        uint numberOfTransforms = transformArray.length;
        return (
            tokenId,
            transformArray[numberOfTransforms - 1].asset.facilityId,
            transformArray[numberOfTransforms - 1].asset.assetState,
            transformArray[numberOfTransforms - 1].asset.assetProcess,
            transformArray[numberOfTransforms - 1].asset.assetQuantity,
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
        uint256 facilityId,
        string memory assetState,
        string memory assetProcess,
        string memory assetUOM,
        uint256 assetQuantity
    ) public {
        (, , , bool assetCommission, ) = facility.get(facilityId);
        require(
            assetCommission == true,
            "Assets can only be created at facilities that produce/commission raw assets"
        );
        tokenAssets[tokenId] = Asset(
            facilityId,
            assetState,
            assetProcess,
            assetUOM,
            assetQuantity
        );
        emit TokenAssetEvent(
            ownerOf(tokenId),
            tokenId,
            facilityId,
            assetState,
            assetProcess,
            assetUOM,
            assetQuantity
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
            string memory,
            uint256
        )
    {
        return (
            tokenId,
            tokenAssets[tokenId].facilityId,
            tokenAssets[tokenId].assetState,
            tokenAssets[tokenId].assetProcess,
            tokenAssets[tokenId].assetUOM,
            tokenAssets[tokenId].assetQuantity
        );
    }
}
