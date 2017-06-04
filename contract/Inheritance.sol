pragma solidity ^0.4.11;

contract Inheritance {

    address owner;

    mapping(address => Funding) heirFunding;
    mapping(address => uint) heirWithdrawal;
    mapping(address => uint) transferWithdrawal;
    uint totalShares;

    uint lastTimeAlive;
    uint lockTime;

    bool disabled;
    bool confirmedDead;

    uint totalAtDeath;

    event Activity(address actor);

    function Inheritance() payable {
        owner = msg.sender;
        lastTimeAlive = now;
        lockTime = 60 days;
    }

    /* Fallback to accept funds from any address while enabled */
    function() payable enabled {}

    modifier enabled() {
        Activity(msg.sender);
        require(!disabled);
        _;
    }

    modifier isOwner() {
        Activity(msg.sender);
        require(msg.sender == owner);
        lastTimeAlive = now;
        _;
    }

    modifier whenDead() {
        Activity(msg.sender);
        require (now >= lastTimeAlive + lockTime);
        disabled = true;
        if (totalAtDeath == 0) {
            totalAtDeath = this.balance;
        }
        _;
    }

    /* Withdraw any allowed funds stored in this contract */
    function withdrawTransfer() {
        uint amount = transferWithdrawal[msg.sender];
        delete transferWithdrawal[msg.sender];
        msg.sender.transfer(amount);
    }

    /* Calculate inheritance amount and mark for withdrawal */
    function requestInheritance() whenDead {
        Funding funding = heirFunding[msg.sender];

        if (funding.shares > 0 && !funding.withdrawn) {
            uint amount = totalAtDeath * funding.shares / totalShares;
            funding.withdrawn = true;
            heirWithdrawal[msg.sender] = amount;
        }
    }

    /* Withdraw funds you have inherited */
    function withdrawInheritance() {
        uint amount = heirWithdrawal[msg.sender];
        delete heirWithdrawal[msg.sender];
        msg.sender.transfer(amount);
    }

    /* Assign ownership to another address */
    function changeOwner(address newOwner) isOwner {
        owner = newOwner;
    }

    function refresh() isOwner {}

    function setLockTimeInDays(uint time) isOwner {
        lockTime = time * 1 days;
    }

    /* Set an heir and their inheritance share */
    function setHeir(address heirAddress, uint shares) isOwner {
        Funding funding = heirFunding[heirAddress];

        if (funding.shares > 0) {
            totalShares -= funding.shares;
            funding.shares = shares;
        } else {
            heirFunding[heirAddress] = Funding(shares, false);
        }

        totalShares += shares;
    }

    /* Remove an heir and their share value */
    function removeHeir(address heirAddress) isOwner {
        Funding funding = heirFunding[heirAddress];
        totalShares -= funding.shares;
        delete heirFunding[heirAddress];
    }

    function drain() isOwner {
        owner.transfer(this.balance);
    }

    /* Explicit deposit to this address */
    function deposit() payable isOwner {}

    /* Allow an address to withdraw a given amount of funds */
    function allowWithdraw(address receiver, uint amount) isOwner enabled {
        require(amount <= this.balance);
        transferWithdrawal[receiver] = amount;
    }

    /* Disable and prevent additional fallback funding */
    function disable() isOwner {
        disabled = true;
    }

    struct Funding {
        uint shares;
        bool withdrawn;
    }
}