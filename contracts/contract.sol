// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @author Roi Di Segni (aka Sheeeev66)
 */

contract Contract is Ownable, ERC721, IERC2981 {

    // Public address of the royalty reciever:
    address private royaltyReciever;
    // Royalty percentage:
    uint256 private royaltyPercentage;

    using Counters for Counters.Counter;

    event NewTokenMinted(uint id, uint dna);
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
     * @notice won't execute if it isn't the owner who is executing the command
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
     * @dev returns: send a percent of the sale price to the royalty recievers address
     * @notice this function is to be called by exchanges to get the royalty information
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "ERC2981RoyaltyStandard: Royalty info for nonexistent token");
        return (royaltyReciever, (salePrice * royaltyPercentage) / 10000);
    }
    
    /**
     * @dev Sets the royalty recieving address to:
     * @param _address the address the royalties are sent to
     * @notice Setting the recieving address to the zero address will result in an error
     */
    function setRoyaltyRecieverTo(address _address) public onlyOwner {
        require(_address != address(0), "Cannot send royalties to the zero address");
        royaltyReciever = _address;
    }
    
    /**
     * @dev Sets the royalty percentage to:
     * @param _royaltyPercentage the percentage of the sale in basis points (0.01% = 1 | 100% = 10000)
     * @dev example: If I want to set 5% so "_royaltyPercentage" will be 500
     */
    function setRoyaltyPercentageTo(uint _royaltyPercentage) public onlyOwner {
        require(_royaltyPercentage <= 2000, "Royalty cannot be more than 20 percent");
        royaltyPercentage = _royaltyPercentage;
    }
    


}