pragma solidity ^0.4.8;
contract owned{
    address public owner;
    function owned() {owner = msg.sender;}
    modifier onlyOwner {if (msg.sender != owner) throw;_;}
    function transferOwnership(address newOwner) onlyOwner {owner = newOwner;}
}
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }
contract Tengri is owned
{
    string public standard = 'Tengri2017';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	bool public activeContract;
	uint256 public sellPrice;
    uint256 public buyPrice;
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public approvedAccount;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event ApprovAccount(address target, bool approve);
    
    modifier isActiveContract { if (!activeContract) throw; _; }
    modifier isApprovedAccount { if (!(approvedAccount[msg.sender] && activeContract)) throw; _; }
   
    function Tengri(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) payable
    {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
		activeContract = true;
		sellPrice = 0;
		buyPrice  = 0;
    }
    
	function setActiveContract (bool active){activeContract = active;}

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    function buy() payable isApprovedAccount returns (uint amount){
        amount = msg.value / buyPrice;                     // calculates the amount
        if (balanceOf[this] < amount) throw;               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                   // adds the amount to buyer's balance
        balanceOf[this] -= amount;                         // subtracts amount from seller's balance
        Transfer(this, msg.sender, amount);                // execute an event reflecting the change
        return amount;                                     // ends function and returns
    }

    function sell(uint amount) isApprovedAccount returns (uint revenue){
        if (balanceOf[msg.sender] < amount ) throw;        // checks if the sender has enough to sell
        balanceOf[this] += amount;                         // adds the amount to owner's balance
        balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller's balance
        revenue = amount * sellPrice;
        if (!msg.sender.send(revenue)) {                   // sends ether to the seller: it's important
            throw;                                         // to do this last to prevent recursion attacks
        } else {
            Transfer(msg.sender, this, amount);             // executes an event reflecting on the change
            return revenue;                                 // ends function and returns
        }
    }

    function approveAccount(address target, bool approve) onlyOwner isActiveContract {
        approvedAccount[target] = approve;
        ApprovAccount(target, approve);
    }
   
    function transfer(address _to, uint256 _value) isApprovedAccount {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }
    
    function () payable isActiveContract {
        if (balanceOf[this] == totalSupply || msg.value == 0) throw;  
    }
}

