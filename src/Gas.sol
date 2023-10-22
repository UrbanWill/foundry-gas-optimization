// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract GasContract {
    
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => bool) private whiteListStructMap_status;
    mapping(address => uint256) private whiteListStructMap_amount;
    mapping(uint256 => address) private admins;
    address immutable contractOwner; // consider making this immutable

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);
    
    constructor(address[] memory _admins, uint256 _totalSupply) {
        
        contractOwner = msg.sender;
        balances[msg.sender] = _totalSupply;
        /*
        for (uint256 ii = 0; ii < 5; ii++) {
            admins[ii] = _admins[ii];
        }
        */
        admins[0] = _admins[0];
        admins[1] = _admins[1];
        admins[2] = _admins[2];
        admins[3] = _admins[3];
        admins[4] = _admins[4];
        
    }

    function balanceOf(address _user) external view returns (uint256 balance_) {
        return balances[_user];
    }

    function transfer(address _recipient, uint256 _amount, string calldata _name) external returns (bool status_) {
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        //payments[msg.sender].push(Payment({amount: _amount, paymentID: ++paymentCounter}));
        return true;
        
    }
    
    function administrators(uint256 numIndex) external view returns (address _addr) {
        return admins[numIndex];
    }
    function addToWhitelist(address _userAddrs, uint256 _tier) external {
        ///////////////////////////////////////////////////////
        if (_tier >= 255) revert();
        ////////////////// IS ADMIN OR OWNER //////////////////
        bool isAdmin = false;
        
        for (uint256 i = 0; i < 5; i++) {
            if (admins[i] == msg.sender) isAdmin = true;
        }
        if (!isAdmin) revert();
        ///////////////////////////////////////////////////////
        
        whitelist[_userAddrs] = _tier > 3 ? 3 : (_tier > 0 ? 2 : 1);
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) external {
        whiteListStructMap_status[msg.sender] = true;
        whiteListStructMap_amount[msg.sender] = _amount;
        // Update sender and recipient balances
        balances[msg.sender] = ( balances[msg.sender] - _amount) + whitelist[msg.sender];
        balances[_recipient] = ( balances[_recipient] + _amount) - whitelist[msg.sender];
        
        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) external view returns (bool, uint256) {
        return (whiteListStructMap_status[sender], whiteListStructMap_amount[sender]);
    }
}