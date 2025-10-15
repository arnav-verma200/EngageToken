// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
  EngageToken

  - No imports
  - No constructor (use init() once after deployment)
  - Simple ERC20-like token
  - Owner can register verifiers
  - Verifiers call issueForEngagement to mint tokens based on engagement metrics
  - Lightweight protections: onlyOwner, onlyVerifier, one-time init, claim nonces
*/

contract EngageToken {
    // ERC20 storage
    string public name = "EngageToken";
    string public symbol = "ENG";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Access control
    address public owner;
    bool public initialized;

    mapping(address => bool) public isVerifier;

    // Prevent replaying the same off-chain claim (each verifier supplies a claimId).
    // claimNonces[verifier][claimId] == true means already used
    mapping(address => mapping(bytes32 => bool)) public claimNonces;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner_, address indexed spender, uint256 value);
    event OwnerInitialized(address indexed owner);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    event IssuedForEngagement(address indexed verifier, address indexed to, uint256 amount, bytes32 claimId);

    // --- ERC20 functions ---

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "zero dest");
        require(balanceOf[from] >= amount, "insufficient");
        unchecked { balanceOf[from] -= amount; }
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        require(currentAllowance >= amount, "allowance");
        allowance[from][msg.sender] = currentAllowance - amount;
        _transfer(from, to, amount);
        return true;
    }

    // --- Initialization & admin management ---

    // Must be called once after deployment to set the owner.
    // No constructor used per request.
    function init() external {
        require(!initialized, "already init");
        owner = msg.sender;
        initialized = true;
        emit OwnerInitialized(owner);
    }

    modifier onlyOwner() {
        require(initialized && msg.sender == owner, "owner only");
        _;
    }

    modifier onlyVerifier() {
        require(isVerifier[msg.sender], "verifier only");
        _;
    }

    // Owner can add or remove verifiers
    function addVerifier(address verifier) external onlyOwner {
        require(verifier != address(0), "zero addr");
        require(!isVerifier[verifier], "already verifier");
        isVerifier[verifier] = true;
        emit VerifierAdded(verifier);
    }

    function removeVerifier(address verifier) external onlyOwner {
        require(isVerifier[verifier], "not verifier");
        isVerifier[verifier] = false;
        emit VerifierRemoved(verifier);
    }

    // --- Engagement-driven issuance ---

    /*
      Verifier supplies:
        - to: recipient address
        - likes, comments, shares: engagement counts (uint256)
        - claimId: arbitrary unique id (off-chain) to prevent double issuance (bytes32)
      Issuance formula (example): 
        base = likes * 1 + comments * 3 + shares * 5
        amountToMint = base * multiplier
      Multiplier is an on-chain value owner can change to tune economics
    */

    uint256 public multiplier = 1; // tunable by owner (in token units; example: 1 means raw base tokens)
    function setMultiplier(uint256 m) external onlyOwner {
        multiplier = m;
    }

    // Example: mint calculation performed inside; no external oracle used here.
    function issueForEngagement(address to, uint256 likes, uint256 comments, uint256 shares, bytes32 claimId) external onlyVerifier returns (uint256) {
        require(to != address(0), "zero dest");
        require(!claimNonces[msg.sender][claimId], "claim used");
        // Weighted formula (simple, changeable)
        // likes -> weight 1, comments -> 3, shares -> 5
        unchecked {
            uint256 base = likes + (comments * 3) + (shares * 5);
            require(base > 0, "no engagement");
            // adjust for decimals
            uint256 amount = base * multiplier * (10 ** decimals);
            _mint(to, amount);
            claimNonces[msg.sender][claimId] = true;
            emit IssuedForEngagement(msg.sender, to, amount, claimId);
            return amount;
        }
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "mint zero");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    // Owner rescue: burn supply from an address if necessary (e.g., to correct mistakes)
    function burnFrom(address from, uint256 amount) external onlyOwner {
        require(balanceOf[from] >= amount, "insufficient");
        unchecked { balanceOf[from] -= amount; totalSupply -= amount; }
        emit Transfer(from, address(0), amount);
    }

    // --- View helpers ---

    function isClaimUsed(address verifier, bytes32 claimId) external view returns (bool) {
        return claimNonces[verifier][claimId];
    }
}
