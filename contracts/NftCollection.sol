// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title NftCollection - basic ERC-721-style NFT collection
/// @notice Skeleton for later implementation of full ERC-721 logic.
contract NftCollection {
    // ============ State variables ============

    // Collection configuration
    string private _name;             // Token collection name
    string private _symbol;           // Token symbol
    uint256 private _maxSupply;       // Maximum tokens that can ever be minted
    uint256 private _totalSupply;     // Number of tokens minted minus burned

    // Ownership and approvals
    mapping(uint256 => address) private _owners;          // tokenId => owner address
    mapping(address => uint256) private _balances;        // owner address => balance
    mapping(uint256 => address) private _tokenApprovals;  // tokenId => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => (operator => approved)

    // Admin / access control
    address private _owner;           // contract owner / admin
    bool private _mintPaused;         // flag to pause/unpause minting

    // Optional metadata storage: base URI + per-token URI override
    string private _baseTokenURI;
    mapping(uint256 => string) private _tokenURIs;

    // ============ Events ============

    // Standard ERC-721 events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Custom events for admin actions
    event MintPaused(bool paused);
    event BaseURIUpdated(string newBaseURI);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Constructor ============

    /// @notice Initializes collection metadata and max supply, sets deployer as owner.
    /// @param name_  Collection name
    /// @param symbol_  Token symbol
    /// @param maxSupply_  Maximum number of tokens that can be minted
    constructor(string memory name_, string memory symbol_, uint256 maxSupply_) {
        _name = name_;
        _symbol = symbol_;
        _maxSupply = maxSupply_;
        _owner = msg.sender;
        _mintPaused = false;
    }

    // ============ Modifiers ============

    /// @dev Restricts function to contract owner.
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner");
        _;
    }

    /// @dev Restricts function so it can only be used when minting is not paused.
    modifier whenMintNotPaused() {
        require(!_mintPaused, "Minting paused");
        _;
    }

    // ============ View functions (metadata & configuration) ============

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function mintPaused() external view returns (bool) {
        return _mintPaused;
    }

    // ============ Core ERC-721 interface ============

    function balanceOf(address owner_) external view returns (uint256) {
        require(owner_ != address(0), "Zero address");
        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), "Owner query for nonexistent token");
        return owner_;
    }

    function approve(address to, uint256 tokenId) external {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), "Approve for nonexistent token");
        require(to != owner_, "Approve to owner");
        require(
            msg.sender == owner_ || _operatorApprovals[owner_][msg.sender],
            "Not owner nor operator"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "Approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "Approve self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner_, address operator) external view returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        // Only owner or approved accounts can move the token
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");

        // The current owner must match "from"
        address owner_ = _owners[tokenId];
        require(owner_ == from, "From is not owner");

        // Cannot send to zero address
        require(to != address(0), "Transfer to zero");

        // Clear any single-token approval
        if (_tokenApprovals[tokenId] != address(0)) {
            delete _tokenApprovals[tokenId];
        }

        // Decrease balance of old owner, increase balance of new owner
        _balances[from] -= 1;
        _balances[to] += 1;

        // Change the owner record
        _owners[tokenId] = to;

        // Emit the Transfer event so off-chain systems know about it
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");

        address owner_ = _owners[tokenId];
        require(owner_ == from, "From is not owner");
        require(to != address(0), "Transfer to zero");

        if (_tokenApprovals[tokenId] != address(0)) {
            delete _tokenApprovals[tokenId];
        }

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external {
        data; // unused, kept for compatibility
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");

        address owner_ = _owners[tokenId];
        require(owner_ == from, "From is not owner");
        require(to != address(0), "Transfer to zero");

        if (_tokenApprovals[tokenId] != address(0)) {
            delete _tokenApprovals[tokenId];
        }

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // ============ Minting & burning ============

    function mint(address to, uint256 tokenId) external whenMintNotPaused onlyOwner {
        require(to != address(0), "Mint to zero");
        require(!_exists(tokenId), "Token already minted");
        require(_totalSupply < _maxSupply, "Max supply reached");

        _owners[tokenId] = to;
        _balances[to] += 1;
        _totalSupply += 1;

        emit Transfer(address(0), to, tokenId);
    }

    function burn(uint256 tokenId) external {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), "Burn nonexistent token");
        require(
            msg.sender == owner_ ||
            msg.sender == _tokenApprovals[tokenId] ||
            _operatorApprovals[owner_][msg.sender],
            "Not owner nor approved"
        );

        // Clear approvals
        if (_tokenApprovals[tokenId] != address(0)) {
            delete _tokenApprovals[tokenId];
        }

        _balances[owner_] -= 1;
        delete _owners[tokenId];
        _totalSupply -= 1;

        emit Transfer(owner_, address(0), tokenId);
    }

    // ============ Admin functions ============

    function pauseMinting() external onlyOwner {
        require(!_mintPaused, "Already paused");
        _mintPaused = true;
        emit MintPaused(true);
    }

    function unpauseMinting() external onlyOwner {
        require(_mintPaused, "Not paused");
        _mintPaused = false;
        emit MintPaused(false);
    }

    function setBaseTokenURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    function transferContractOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is zero");
        address previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    // ============ Metadata functions ============

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory customURI = _tokenURIs[tokenId];
        if (bytes(customURI).length != 0) {
            return customURI;
        }

        require(bytes(_baseTokenURI).length != 0, "Base URI not set");
        return string(abi.encodePacked(_baseTokenURI, _toString(tokenId)));
    }

    // ============ Internal helpers ============

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), "Operator query for nonexistent token");
        return (
            spender == owner_ ||
            spender == _tokenApprovals[tokenId] ||
            _operatorApprovals[owner_][spender]
        );
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "URI set for nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
