// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract GasContract {
    address[5] public administrators;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public whiteListStruct;
    address contractOwner; // consider making this immutable
    // @dev - 0x01 = tradeFlag, 0x02 = dividendFlag
    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    function isAdminOrOwner() internal view {
        address senderOfTx = msg.sender;
        bool admin;
        for (uint256 i = 0; i < 5; i++) {
            if (administrators[i] == senderOfTx) {
                admin = true;
            }
        }
        if (!admin || senderOfTx != contractOwner) revert("onlyAdminOrOwner");
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        address senderOfTx = msg.sender;
        balances[senderOfTx] = _totalSupply;
        for (uint256 ii = 0; ii < 5; ii++) {
            address tempAdmin = _admins[ii];
            administrators[ii] = tempAdmin;
        }
    }

    function balanceOf(address _user) external view returns (uint256 balance_) {
        balance_ = balances[_user];
    }

    function transfer(address _recipient, uint256 _amount, string calldata _name) public returns (bool status_) {
        if (balances[msg.sender] < _amount) revert("insufficientBalance");
        if (bytes(_name).length >= 9) revert("min9chars");
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        return true;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public {
        isAdminOrOwner();
        if (_tier >= 255) revert("tierMustBeLT255");

        whitelist[_userAddrs] = _tier;
        if (_tier > 3) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 3;
        } else if (_tier == 1) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 1;
        } else if (_tier > 0 && _tier < 3) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 2;
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        uint256 usersTier = whitelist[msg.sender];
        if (usersTier <= 0 || usersTier >= 4) revert("incorrectTier");
        whiteListStruct[msg.sender] = _amount;
        if (balances[msg.sender] < _amount) revert("insufficientBalance");
        // if (_amount <= 3) revert("reqAmmountGT3");

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        balances[msg.sender] += whitelist[msg.sender];
        balances[_recipient] -= whitelist[msg.sender];

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) public view returns (bool, uint256) {
        return (true, whiteListStruct[sender]);
    }
}
