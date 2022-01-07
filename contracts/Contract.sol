// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./IERC2981.sol";
import "./ERC721.sol";

/**
 * @author Roi Di Segni (aka @sheeeev66)
 */

contract Contract is Ownable, ERC721, IERC2981 {

    // Public address of the royalty receiver:
    address private royaltyReceiver;
    // Royalty Percentage:
    uint16 private royaltyPercentage;

    // Launch (when true its launched)
    bool private launched;
    // check if the team minted or not
    bool private teamMintAvalible = true;

    // base URI
    string private baseURIcid;

    using Counters for Counters.Counter;
    using Strings for uint256;

    event NewNameMinted(uint id);
    event Withdrawn(address _address, uint amount);
    
    // track token ID
    Counters.Counter private _tokenId;

    // To enforce the pre mint phase
    mapping(address => bool) preMintParticipant;


    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) { }


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
        emit Withdrawn(_address, address(this).balance);
        _address.transfer(address(this).balance);
    }
    
    /**
     * @dev Launch the project
     */
    function launch() public onlyOwner {
        require(launched == false, "TraditionerativeArt: Already Launched");
        launched = true;
    }

    /**
     * @dev this function should be called after *all the art is generated* and uploaded to IPFS.
     * @notice calling this function enables minting!! So don't call it unless you are sure.
     * @notice RECOMMENDED NOT TO CALL THIS FUNCTION UNTILL ALL THE ART IS UPLOADED TO IPFS!!
     */
    function setBaseURIcid(string calldata cid) public onlyOwner {
        baseURIcid = cid;
    }

    /**
     * @dev Overriding this to return ipfs URI with a set CID.
     * @notice If no IPFS CID is set yet, it will return a domain to where the metadata is stored with a path to it.
     * 
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURIcid).length > 0 ? 
        string(abi.encodePacked("ipfs://", baseURIcid, "/", tokenId.toString(), ".json")) : 
        string(abi.encodePacked("https://  ", tokenId.toString()));
    }

    /**
     * @dev premint for team
     * @dev 20 will be minted for the team
     * @notice the NFTs will be minted and sent to the callers address
     * @notice only the owner of the contract can call this function
     * @notice enables pre minting
     */
    function teamMintName() public onlyOwner {
        // require(bytes(baseURIcid).length > 0, "No IPFS CID set. Minting will be enabled once setBaseURIcid(cid) will be called");
        require(teamMintAvalible, "Team Mint Has already happened");
        for (uint i=0; i < 20; i++) {
            _safeMint(msg.sender, _tokenId.current());

            emit NewNameMinted(_tokenId.current());
            _tokenId.increment();
        }
        teamMintAvalible = false;
    }

    /**
     * @dev pre minting the token (the number of pre mint participants will be minted)
     * @dev For people who want to participate but aren't capable to particpate because of gas wars
     * @notice enabled once teamMint() is called
     * @notice only eligable people can pre minutes
     * @notice pre minting can only 
     */
    function preMintName() public /* payable */ { 
        // require(teamMintAvalible == false, "Pre minting isn't yet avalible");
        // require(launched == false, "Pre mint phase is over. Please use safeMintTga(tokenCount))");
        // require(preMintParticipant[msg.sender], "Address not eligable for a pre mint");
        // require(msg.value >= 10000000000000000, "Ether value sent is not correct"); // price for 1: 0.01 eth

        _safeMint(msg.sender, _tokenId.current());

        emit NewNameMinted(_tokenId.current());
        _tokenId.increment();
        
        preMintParticipant[msg.sender] = false;
    }

    /**
     * @dev miniting the token
     * @dev makes sure that no more than 10K tokens are minted
     * @dev makes sure that at least 0.05 ether is paid before minting
     * @dev makes sure that no more than 20 tokens are minted at once
     * @param _tokenCount the ammount of tokens to mint
     */
    function mintName(uint _tokenCount) public payable {
        require(launched, "Minting has not yet started");
        require(_tokenCount <= 20, "Can not mint more than 20 tokens at a time");
        require(_tokenCount != 0, "You have to mint at least 1 token");
        require(_tokenId.current() + _tokenCount <= 9899, "Purchace will exeed max supply of tokens");
        require(msg.value >= 10000000000000000*_tokenCount, "Ether value sent is not correct"); // price for 1: 0.01 eth

        for (uint i=0; i < _tokenCount; i++) {
            _safeMint(msg.sender, _tokenId.current());

            emit NewNameMinted(_tokenId.current());
            _tokenId.increment();
        }
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
        return (royaltyReceiver, (salePrice * royaltyPercentage) / 10000);
    }
    
    /**
     * @dev Sets the royalty recieving address to:
     * @param _address the address the royalties are sent to
     * @notice Setting the recieving address to the zero address will result in an error
     */
    function setRoyaltyRecieverTo(address _address) public onlyOwner {
        require(_address != address(0), "Can not send royalties to the zero address");
        royaltyReceiver = _address;
    }

    /**
     * @dev Sets the royalty percentage to:
     * @param _percent the percentage in basis points.
     * @notice When entering royalty, make sure you are using basis points (points per 10000).
     * @dev Usage example:
     * setRoyaltyAmountTo(500); // this will set 5 percent. Think of it as 5.00 but without the decimal point.
     * @dev This is to handle the decimals in solidity. Because solidity doesn't support floats.
     */
    function setRoyaltyAmountTo(uint16 _percent) public onlyOwner {
        require(_percent >= 0 && _percent <= 20000, "Royalty can only be between 0-20 percent of the sale");
        royaltyPercentage = _percent;
    }
    
    /**
     * @dev get if the caller owns an NFT
     */
    function isTokenHolder() external view returns(bool) {
        return balanceOf(msg.sender) > 0;
    }

}