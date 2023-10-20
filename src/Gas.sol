// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract GasContract {
    address[5] public administrators;
    uint256 totalSupply = 0; // consider making this immutable
    uint256 paymentCounter = 0;
    mapping(address => uint256) public balances;
    mapping(address => Payment[]) payments;
    mapping(address => uint256) public whitelist;
    address contractOwner; // consider making this immutable
    // @dev - 0x01 = tradeFlag, 0x02 = dividendFlag
    uint8 constant FLAGS = 3;
    uint8 constant TRADE_PERCENT = 12;

    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    struct ImportantStruct {
        uint256 amount;
        uint256 valueA; // max 3 digits
        uint256 bigValue;
        uint256 valueB; // max 3 digits
        bool paymentStatus;
        address sender;
    }

    mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(address admin, uint256 ID, uint256 amount, string recipient);
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
        totalSupply = _totalSupply;
        address senderOfTx = msg.sender;
        balances[senderOfTx] = _totalSupply;
        emit supplyChanged(senderOfTx, _totalSupply);
        for (uint256 ii = 0; ii < 5; ii++) {
            address tempAdmin = _admins[ii];
            administrators[ii] = tempAdmin;
        }
    }

    function balanceOf(address _user) external view returns (uint256 balance_) {
        uint256 balance = balances[_user];
        return balance;
    }

    function getPayments(address _user) public view returns (Payment[] memory payments_) {
        return payments[_user];
    }

    function transfer(address _recipient, uint256 _amount, string calldata _name) public returns (bool status_) {
        address senderOfTx = msg.sender;
        if (balances[senderOfTx] < _amount) revert("insufficientBalance");
        if (bytes(_name).length >= 9) revert("min9chars");
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        Payment memory payment;
        payment.admin = address(0);
        payment.adminUpdated = false;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name;
        payment.paymentID = ++paymentCounter;
        payments[senderOfTx].push(payment);
        bool[] memory status = new bool[](TRADE_PERCENT);
        for (uint256 i = 0; i < TRADE_PERCENT; i++) {
            status[i] = true;
        }
        return (status[0] == true);
    }

    function updatePayment(address _user, uint256 _ID, uint256 _amount, PaymentType _type) public {
        isAdminOrOwner();
        address senderOfTx = msg.sender;

        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            if (payments[_user][ii].paymentID == _ID) {
                payments[_user][ii].adminUpdated = true;
                payments[_user][ii].admin = _user;
                payments[_user][ii].paymentType = _type;
                payments[_user][ii].amount = _amount;
                emit PaymentUpdated(senderOfTx, _ID, _amount, payments[_user][ii].recipientName);
            }
        }
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
        address senderOfTx = msg.sender;
        uint256 usersTier = whitelist[senderOfTx];
        if (usersTier <= 0 || usersTier >= 4) revert("incorrectTier");
        whiteListStruct[senderOfTx] = ImportantStruct(_amount, 0, 0, 0, true, msg.sender);
        if (balances[senderOfTx] < _amount) revert("insufficientBalance");
        if (_amount <= 3) revert("reqAmmountGT3");

        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        balances[senderOfTx] += whitelist[senderOfTx];
        balances[_recipient] -= whitelist[senderOfTx];

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) public view returns (bool, uint256) {
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }
}
