pragma solidity ^0.5.14;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract MicrobatchToken is ERC721Full, Ownable {
    constructor() public ERC721Full("MICROBATCH", "MBAT") {}
    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }
    function _mint(address to) public onlyOwner {
        mint(to, totalSupply().add(1));
    }
}
