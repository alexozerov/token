pragma solidity ^0.4.10;
contract owned{
    address public owner;
    function owned() {owner = msg.sender;}
    modifier onlyOwner {if (msg.sender != owner) throw;_;}
    function transferOwnership(address newOwner) onlyOwner {owner = newOwner;}
}
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }
contract GreenECH is owned
{
    string public standard = 'GreenECH';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	bool public activeContract;
	uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public issuePrice;
    uint minBalanceForAccounts;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public approvedAccount;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event ApprovAccount(address target, bool approve);
    
    modifier isActiveContract { if (!activeContract) throw; _; }
    modifier isApprovedAccount(address _to) { 
    	if (!(approvedAccount[_to] && activeContract)) throw; _;
    }
   
    function GreenECH(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) payable
    {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
		activeContract = true;
		sellPrice = 1;
		buyPrice  = 1;
		issuePrice = 1;                     //First issue Price. Use For addissue sell
		approvedAccount[this] = true;
    }
    
	function setActiveContract (bool active){activeContract = active;}

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    function buy() payable isApprovedAccount(msg.sender) returns (uint amount){
        amount = msg.value / buyPrice;                     // calculates the amount
        if (balanceOf[this] < amount) throw;               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                   // adds the amount to buyer's balance
        balanceOf[this] -= amount;                         // subtracts amount from seller's balance
        Transfer(this, msg.sender, amount);                // execute an event reflecting the change
        return amount;                                     // ends function and returns
    }

    function sell(uint amount) isApprovedAccount(msg.sender) returns (uint revenue){
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
   
    function transfer(address _to, uint256 _value) isApprovedAccount (_to) {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        if (msg.sender.balance<minBalanceForAccounts) sell((minBalanceForAccounts-msg.sender.balance)/sellPrice);
        //if (_to.balance<minBalanceForAccounts) _to.send(sell((minBalanceForAccounts-_to.balance)/sellPrice));
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }
    
    function addIssueToken(address target, uint256 issuedAmount) onlyOwner {
    balanceOf[target] += issuedAmount;
    totalSupply += issuedAmount;
    Transfer(0, owner, issuedAmount);
    Transfer(owner, target, issuedAmount);
}
    
    function setMinBalance(uint minimumBalanceInFinney) onlyOwner {
        minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }
    
    function () payable isActiveContract {
        if (balanceOf[this] == totalSupply || msg.value == 0) throw;  
    }
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal; uint public amountRaised; uint public deadline; uint public price;
    GreenECH public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    event GoalReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    bool crowdsaleClosed = false;

    /* data structure to hold information about campaign contributors */

    /*  at initialization, setup the owner */
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        GreenECH addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 ether;
        tokenReward = GreenECH(addressOfTokenUsedAsReward);
    }

    /* The function without name is the default function that is called whenever anyone sends funds to a contract */
    function () payable {
        if (crowdsaleClosed) throw;
        uint amount = msg.value;
        balanceOf[msg.sender] = amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);
        FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    /* checks if the goal or time limit has been reached and ends the campaign */
    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    function safeWithdrawal() afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
}