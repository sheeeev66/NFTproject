// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @author Roi Di Segni (aka Sheeeev66)
 * @dev 
 */

contract Contract is Ownable, ERC721, IERC2981 {

    // Public address of the royalty reciever:
    address royaltyReciever;
    // Royalty Amount:
    uint256 royaltyAmount;

    using Counters for Counters.Counter;

    event NewTokenMinted(uint tgaId, uint dna);
    event Withdrawn(address _address, uint amount);
    
    // track token ID
    Counters.Counter private _tokenId;

    constructor() ERC721("name", "AAA") { }


    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    /**
     * @dev withdraw contract balance to a wallet
     * @dev won't execute if it isn't the owner who is executing the command
     * @param _address the address to withdraw to
     */
    function withdraw(address payable _address) public onlyOwner {
        uint contractBal = address(this).balance;
        _address.transfer(contractBal);
        emit Withdrawn(_address, contractBal);
    }

    /**
     * @dev setting base URI
     */
    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    /**
     * @dev miniting the token
     * @dev makes sure that no more than 10K tokens are minted
     * @dev makes sure that at least 0.01 ether is paid before minting
     * @dev makes sure that no more than 20 tokens are minted at once
     * @param _tokenCount the ammount of tokens to mint
     */
    function safeMint(uint _tokenCount) public payable {
        require(_tokenCount <= 20, "Can't mint more than 20 tokens at a time");
        require(msg.value >= 0.01 ether, "Ether value sent is not correct");

        for (uint i=0; i < _tokenCount; i++) {
            require(_tokenId.current() <= 9999, "No more tokens avalible");
            uint32 id = uint32(_tokenId.current());

            _safeMint(msg.sender, id);

            emit NewTokenMinted(id, _generateRandomDna());
            _tokenId.increment();
        }
    }
    
    /**
     * @dev Generates random number for the DNA by using the timestamp, block difficulty and the block number.
     * @return random DNA
     */
    function _generateRandomDna() private view returns (uint32) {
        uint rand = uint(keccak256(abi.encodePacked(block.difficulty, block.number, block.timestamp)));
        return uint32(rand %  /* DNA modulus: 10 in the power of "dna digits" (in this case: 8) */ (10 ** 8) );
    }

    /**
     * @dev Royalty info for the exchange to read (using EIP-2981 royalty standard)
     * @param tokenId the token Id 
     * @param salePrice the price the NFT was sold for
     * @dev return: send 5% royalty to the "royaltyReciever"
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "ERC2981RoyaltyStandard: Royalty info for nonexistent token");
        return (royaltyReciever, salePrice * 500 /*percentage in basis points (5%)*/ / 10000);
    }
    
    function setRoyaltyRecieverTo(address _address) public onlyOwner {
      royaltyReciever = _address;
    }
    
    function setRoyaltyTouint256(uint _royaltyAmount) public onlyOwner {
      royaltyAmount = _royaltyAmount;
    }
    


}