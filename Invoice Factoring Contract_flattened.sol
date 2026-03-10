
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: tempo_testnet/Invoice Factoring Contract.sol


pragma solidity ^0.8.20;

/**
 * @title BaseFactor Protocol
 * @dev Enterprise-grade peer-to-peer invoice factoring.
 * Solves cash-flow problems for SMEs by allowing them to sell unpaid invoices at a discount.
 *
 * State Machine:
 * [Draft] -> [Verified by Auditor] -> [Funded by Investor] -> [Repaid by Debtor]
 */
contract InvoiceFactoring is ReentrancyGuard, Ownable {
    
    enum Status { Pending, Verified, Funded, Repaid, Defaulted }

    struct Invoice {
        uint256 id;
        address seller;       // The SME needing cash
        address investor;     // The entity providing liquidity
        string clientName;    // Who owes the money (e.g., "Acme Corp")
        string invoiceURI;    // IPFS link to the actual invoice PDF
        uint256 faceValue;    // The total amount owed (in Wei)
        uint256 fundingAmount;// How much the seller wants NOW (Discounted, in Wei)
        uint256 dueDate;      // Unix timestamp
        Status status;
    }

    mapping(uint256 => Invoice) public invoices;
    uint256 public invoiceCount;

    // Events for the decentralized application to index
    event InvoiceCreated(uint256 indexed id, address indexed seller, uint256 faceValue, uint256 fundingAmount);
    event InvoiceVerified(uint256 indexed id);
    event InvoiceFunded(uint256 indexed id, address indexed investor);
    event InvoiceRepaid(uint256 indexed id);
    event InvoiceDefaulted(uint256 indexed id);

    // The deployer acts as the Initial Auditor to prevent spam/fake invoices
    constructor() Ownable(msg.sender) {}

    /**
     * @dev 1. SME creates a request to sell an unpaid invoice.
     */
    function createInvoice(
        string memory _clientName, 
        string memory _uri, 
        uint256 _faceValue, 
        uint256 _fundingAmount, 
        uint256 _daysUntilDue
    ) public {
        require(_faceValue > _fundingAmount, "Funding must be less than face value (creates the yield)");
        require(_daysUntilDue > 0, "Due date must be in the future");

        uint256 id = invoiceCount++;
        
        invoices[id] = Invoice({
            id: id,
            seller: msg.sender,
            investor: address(0),
            clientName: _clientName,
            invoiceURI: _uri,
            faceValue: _faceValue,
            fundingAmount: _fundingAmount,
            dueDate: block.timestamp + (_daysUntilDue * 1 days),
            status: Status.Pending
        });

        emit InvoiceCreated(id, msg.sender, _faceValue, _fundingAmount);
    }

    /**
     * @dev 2. Auditor verifies the real-world paperwork is legitimate.
     */
    function verifyInvoice(uint256 _id) public onlyOwner {
        require(_id < invoiceCount, "Invalid ID");
        require(invoices[_id].status == Status.Pending, "Invoice not pending");
        
        invoices[_id].status = Status.Verified;
        emit InvoiceVerified(_id);
    }

    /**
     * @dev 3. Investor provides liquidity. Funds are sent INSTANTLY to the SME.
     */
    function fundInvoice(uint256 _id) public payable nonReentrant {
        Invoice storage inv = invoices[_id];
        
        require(inv.status == Status.Verified, "Invoice not verified by auditor yet");
        require(msg.value == inv.fundingAmount, "Must send exact funding amount");
        require(msg.sender != inv.seller, "You cannot fund your own invoice");

        inv.investor = msg.sender;
        inv.status = Status.Funded;

        // Route the liquidity directly to the SME who needs cash flow
        (bool success, ) = inv.seller.call{value: msg.value}("");
        require(success, "Transfer to SME failed");

        emit InvoiceFunded(_id, msg.sender);
    }

    /**
     * @dev 4. The Corporation (or the SME on their behalf) pays the invoice.
     * The Face Value (Principal + Yield) is routed directly to the Investor.
     */
    function repayInvoice(uint256 _id) public payable nonReentrant {
        Invoice storage inv = invoices[_id];
        
        require(inv.status == Status.Funded, "Invoice is not currently funded");
        require(msg.value == inv.faceValue, "Must repay exact face value");

        inv.status = Status.Repaid;

        // Route the repayment to the Investor
        (bool success, ) = inv.investor.call{value: msg.value}("");
        require(success, "Transfer to Investor failed");

        emit InvoiceRepaid(_id);
    }

    /**
     * @dev 5. If the Corporation fails to pay past the due date, mark as defaulted.
     * In the real world, this triggers off-chain collections / legal action.
     */
    function markDefault(uint256 _id) public {
        Invoice storage inv = invoices[_id];
        require(inv.status == Status.Funded, "Invoice not funded");
        require(block.timestamp > inv.dueDate, "Invoice is not past due yet");

        inv.status = Status.Defaulted;
        emit InvoiceDefaulted(_id);
    }

    // --- View Functions ---
    function getAllInvoices() public view returns (Invoice[] memory) {
        Invoice[] memory all = new Invoice[](invoiceCount);
        for (uint256 i = 0; i < invoiceCount; i++) {
            all[i] = invoices[i];
        }
        return all;
    }
}