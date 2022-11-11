//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./ISoulbound.sol";

contract Soulbound is IERC721, EIP712, ISoulbound {
    using Strings for uint256;

    bytes32 private constant MINT_TYPEHASH =
        keccak256("Mint(address verifier,address to,uint256 nonce,string uri)");

    address private verifier;
    // Mapping from token ID to owner address
    mapping(uint256 => address) private owners;
    // Mapping from owner address to his token
    mapping(address => uint256) private tokens;
    // Mapping from token to its URI
    mapping(uint256 => string) private tokenUris;
    // Keeping track of nonces of every user
    mapping(address => uint256) public nonces;
    // Track ID
    uint256 public currentTokenId = 1;
    /// @notice Token name
    string public name;
    /// @notice Token symbol
    string public symbol;

    // Checks if token actually exists
    modifier tokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) revert TOKEN_NOT_EXIST();
        _;
    }

    modifier onlyVerifier() {
        if (msg.sender != verifier)
            revert NOT_VERIFIED_SENDER({actualSender: msg.sender});
        _;
    }

    constructor(
        address _verifier,
        string memory _name,
        string memory _symbol
    ) EIP712(_name, "1") {
        verifier = _verifier;
        name = _name;
        symbol = _symbol;
    }

    function mint(MintParams calldata params, bytes calldata signature)
        external
    {
        if (params.nonce != nonces[msg.sender])
            revert INVALID_NONCE({
                requestedNonce: params.nonce,
                actualNonce: nonces[msg.sender]
            });
        if (params.to == address(0)) revert ZERO_ADDRESS();
        if (tokens[params.to] != 0) revert ONLY_ONE_TOKEN();

        bytes32 structHash = keccak256(
            abi.encode(
                MINT_TYPEHASH,
                params.verifier,
                params.to,
                params.nonce,
                keccak256(abi.encodePacked(params.uri))
            )
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);
        if (signer != verifier)
            revert NOT_VERIFIED_SIGNER({actualSender: signer});

        uint256 id = currentTokenId;
        owners[id] = params.to;
        tokens[params.to] = id;
        tokenUris[id] = params.uri;

        unchecked {
            currentTokenId++;
        }

        emit Transfer(address(0), params.to, id);
    }

    function burn() external {
        address owner = msg.sender;
        uint256 tokenId = tokens[owner];
        _burn(owner, tokenId);
        emit OwnerRevoke(owner, tokenId);
    }

    function burnFrom(address owner) external onlyVerifier {
        uint256 tokenId = tokens[owner];
        _burn(owner, tokenId);
        emit IssuerRevoke(owner, tokenId);
    }

    function tokenOf(address owner) external view returns (uint256) {
        if (owner == address(0)) revert ZERO_ADDRESS();
        return tokens[owner];
    }

    function ownerOf(uint256 tokenId)
        external
        view
        override(IERC721, ISoulbound)
        tokenExists(tokenId)
        returns (address)
    {
        return _ownerOf(tokenId);
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        return tokenUris[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {}

    function balanceOf(address owner) external view returns (uint256 balance) {}

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure {
        revert SOULBOUND_NOT_SUPPORTED();
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external pure {
        revert SOULBOUND_NOT_SUPPORTED();
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external pure {
        revert SOULBOUND_NOT_SUPPORTED();
    }

    function approve(address, uint256) external pure {
        revert SOULBOUND_NOT_SUPPORTED();
    }

    function setApprovalForAll(address, bool) external pure {
        revert SOULBOUND_NOT_SUPPORTED();
    }

    function getApproved(uint256) external pure virtual returns (address) {
        revert SOULBOUND_NOT_SUPPORTED();
    }

    function isApprovedForAll(address, address) external pure returns (bool) {
        revert SOULBOUND_NOT_SUPPORTED();
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return owners[tokenId];
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _burn(address owner, uint256 tokenId) internal {
        if (tokenId == 0) revert ZERO_TOKEN_ID();
        delete owners[tokenId];
        delete tokens[owner];
        delete tokenUris[tokenId];
    }
}
