//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

interface ISoulbound {
    struct MintParams {
        address verifier;
        address to;
        uint256 nonce;
        string uri;
    }

    // Emitted when an issuer burns a soul
    event IssuerRevoke(address indexed from, uint256 indexed tokenId);
    // Emitted when an owner burns a soul
    event OwnerRevoke(address indexed from, uint256 indexed tokenId);

    error TOKEN_NOT_EXIST();

    error ZERO_ADDRESS();

    error ZERO_TOKEN_ID();

    error ONLY_ONE_TOKEN();

    error SOULBOUND_NOT_SUPPORTED();

    error NOT_VERIFIED_SENDER(address actualSender);

    error NOT_VERIFIED_SIGNER(address actualSender);

    error INVALID_NONCE(uint256 requestedNonce, uint256 actualNonce);

    function tokenOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}
