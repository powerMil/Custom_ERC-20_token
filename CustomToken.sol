// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CustomToken is ERC20, Ownable, Pausable {
    using SafeMath for uint256;
    // Maximum acceptable amount of Ether that can be deposited
uint256 private constant MAX_ACCEPTABLE_ETHER = 10 ether;
    address public _liquidityWallet;
    address public _marketingWallet;
   uint256 private constant TOTAL_SUPPLY = 1_000_000_000 * 10**18;
    uint256 private constant MAX_TRANSACTION_AMOUNT = 100_000_000 * 10**18;
    uint256 private _maxTxAmount = 100_000_000 * 10**18; // Maximum transfer amount to avoid whales

    mapping(address => bool) private _isExcludedFromFee;
    // Event emitted when Ether is deposited to the contract
event EtherDeposited(address indexed sender, uint256 amount);

    constructor(address owner_, address liquidityWallet, address marketingWallet) ERC20("CustomToken", "CTK") Ownable(owner_) {
        _liquidityWallet = liquidityWallet;
        _marketingWallet = marketingWallet;
        _isExcludedFromFee[owner_] = true;
        _isExcludedFromFee[address(this)] = true;
        _mint(owner_, TOTAL_SUPPLY);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view whenNotPaused {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    require(amount <= MAX_TRANSACTION_AMOUNT || _isExcludedFromFee[from], "Transfer amount exceeds the maxTxAmount.");
}


   function excludeFromFee(address account, bool excluded) public onlyOwner {
    _isExcludedFromFee[account] = excluded;
    emit AccountExcludedFromFee(account, excluded); // Emitting AccountExcludedFromFee event
}

   function setMaxTxAmount(uint256 maxTxAmount) public onlyOwner {
    require(maxTxAmount > 0, "Max transaction amount must be greater than zero");
    _maxTxAmount = maxTxAmount;
    emit MaxTxAmountUpdated(maxTxAmount); // Emitting MaxTxAmountUpdated event
}

   function withdrawEther(uint256 amount) public onlyOwner {
    require(address(this).balance >= amount, "Insufficient contract balance");
    require(amount > 0, "Withdrawal amount must be greater than zero");

    _pause(); // Pause the contract

    // Effects: Update state
    _unpause(); // Unpause the contract

    // Interactions: Perform external interaction using call
    (bool success, ) = payable(owner()).call{value: amount}("");
    require(success, "Ether transfer failed");
}




 // Function to update the liquidity wallet address
    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != address(0), "Invalid liquidity wallet address");
        _liquidityWallet = newLiquidityWallet;
    }

    // Function to update the marketing wallet address
    function updateMarketingWallet(address newMarketingWallet) public onlyOwner {
        require(newMarketingWallet != address(0), "Invalid marketing wallet address");
        _marketingWallet = newMarketingWallet;
    }


    function emergencyPause() public onlyOwner {
        _pause();
    }

    function emergencyUnpause() public onlyOwner {
        _unpause();
    }

   receive() external payable {
    require(msg.value > 0, "Fallback function requires non-zero Ether amount");
    require(msg.value <= MAX_ACCEPTABLE_ETHER, "Exceeded maximum acceptable Ether amount");
    emit EtherDeposited(msg.sender, msg.value);
}


    // Events
    event MaxTxAmountUpdated(uint256 newMaxTxAmount);
    event AccountExcludedFromFee(address account, bool excluded);
}
