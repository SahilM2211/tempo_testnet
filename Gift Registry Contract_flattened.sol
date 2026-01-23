
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

// File: tempo_testnet/Gift Registry Contract.sol


pragma solidity ^0.8.20;


/**
 * @title DecentralizedRegistry
 * @dev A smart contract for weddings, birthdays, or fundraising wishlists.
 * 1. Owner adds items with a price.
 * 2. Guests "buy" items (send ETH).
 * 3. Funds go instantly to the Owner.
 * 4. Item is marked as purchased forever.
 *
 * Deployment: Easy (No inputs).
 */
contract GiftRegistry is Ownable {

    struct Item {
        uint256 id;
        string name;
        uint256 price; // in wei
        bool isPurchased;
        address giftedBy; // Address of the guest
        string guestMessage; // "Happy Wedding!"
    }

    Item[] public items;

    event ItemAdded(uint256 indexed id, string name, uint256 price);
    event ItemGifted(uint256 indexed id, address indexed guest, string message);
    
    // Easy deploy: Deployer is the "Celebrant" (Owner)
    constructor() Ownable(msg.sender) {}

    /**
     * @dev Owner adds an item to the wishlist.
     */
    function addItem(string memory _name, uint256 _price) public onlyOwner {
        require(_price > 0, "Price must be > 0");
        
        items.push(Item({
            id: items.length,
            name: _name,
            price: _price,
            isPurchased: false,
            giftedBy: address(0),
            guestMessage: ""
        }));

        emit ItemAdded(items.length - 1, _name, _price);
    }

    /**
     * @dev Guest buys an item. Funds are sent to owner instantly.
     */
    function giftItem(uint256 _id, string memory _message) public payable {
        require(_id < items.length, "Item does not exist");
        Item storage item = items[_id];

        require(!item.isPurchased, "Item already gifted!");
        require(msg.value >= item.price, "Insufficient ETH sent for this item");

        // Mark as purchased
        item.isPurchased = true;
        item.giftedBy = msg.sender;
        item.guestMessage = _message;

        // Forward funds to the owner (Celebrant)
        (bool success, ) = owner().call{value: msg.value}("");
        require(success, "Transfer to owner failed");

        emit ItemGifted(_id, msg.sender, _message);
    }

    /**
     * @dev Owner can remove an item if it hasn't been bought yet.
     * (We just hide it by keeping it in array but you could use a mapping for complex logic)
     * For this simple version, we don't implement delete to keep gas low and array simple.
     */

    // --- View Functions ---
    function getItemCount() public view returns (uint256) {
        return items.length;
    }

    function getAllItems() public view returns (Item[] memory) {
        return items;
    }
}