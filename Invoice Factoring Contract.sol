// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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