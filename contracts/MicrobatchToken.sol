pragma solidity ^0.5.14;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract MicrobatchToken is ERC721Full, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    // emitted when an asset is associated with the token
    event TokenAssetEvent(
        address tokenOwner,
        uint256 tokenId,
        string facilityId,
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
        string facilityId; // facility currently housing the asset
        string assetState; // state asset is currently in, such as raw, finished
        string assetProcess; // step asset is currently in, such as wash, dry, roast
        string assetUOM; //unit of measure, such as KG
        uint256 assetQuantity; // measured in terms of UOM, e.g. 500kg
    }

    // Coffee is transformed as it progresses through the supply chain, from raw beans, to washed, to dried, to roasted, etc.
    // the production line processing is captured in this struct, and the associated mapping below
    struct AssetTransformations {
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

    function setTokenAsset(
        uint256 tokenId,
        string memory facilityId,
        string memory assetState,
        string memory assetProcess,
        string memory assetUOM,
        uint256 assetQuantity
    ) public {
        tokenAssets[tokenId] = Asset(
            facilityId,
            assetState,
            assetProcess,
            assetUOM,
            assetQuantity
        );
        emit TokenAssetEvent(ownerOf(tokenId), tokenId, facilityId, assetState, assetProcess, assetUOM, assetQuantity);
    }

}
