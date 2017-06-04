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

    /* Store the total at first post-death access so shares are calculated from constant balance */
    uint totalAtDeath;

    /* Emit an event on each push action, notifying of possible malicious activity */
    event Activity(address actor);

    function Inheritance() payable {
        owner = msg.sender;
        lastTimeAlive = now;
        lockTime = 60 days;
    }

    /* Accept funds from any address while enabled */
    function() payable enabled {}

    /* Only run when owner is alive and has not disabled contract */
    modifier enabled() {
        Activity(msg.sender);
        require(!disabled);
        _;
    }

    /* Only allow access by owner of contract */
    modifier isOwner() {
        Activity(msg.sender);
        require(msg.sender == owner);
        lastTimeAlive = now;
        _;
    }

    /* Only run when owner is presumed dead */
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

    /* Prove owner is alive */
    function refresh() isOwner {}

    /* Update the lock time (also resets last alive time) */
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

    /* Drain this contract in case of an emergency */
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

    /* Persist the share amount with a withdrawn state toggleable*/
    struct Funding {
        uint shares;
        bool withdrawn;
    }
}