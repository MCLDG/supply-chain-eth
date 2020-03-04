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

    // Coffee is transformed as it progresses through the supply chain, from raw beans, to washed, to dried, to roasted, etc.
    // the production line processing is captured in this struct, and the associated mapping below
    struct AssetTransformation {
        uint256 timestamp; // when the transformation took place
        Asset asset; // the asset prior to the transformation
    }

    // Mapping from token ID to asset represented by the token
    mapping(uint256 => Asset) private tokenAssets;

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
