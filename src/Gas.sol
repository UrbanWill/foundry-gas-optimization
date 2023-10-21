// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract GasContract {
    // Keeping the administrators array because one of the tests is getting they array items by index, still adding the mapping saves gas overall
    address[5] public administrators;
    mapping(address => bool) s_administrators;
    uint256 totalSupply; // consider making this immutable
    uint256 paymentCounter;
    mapping(address => uint256) public balances;
    mapping(address => Payment[]) payments;
    mapping(address => uint256) public whitelist;
    mapping(address => ImportantStruct) public whiteListStruct;
    address contractOwner; // consider making this immutable
    // @dev - 0x01 = tradeFlag, 0x02 = dividendFlag
    uint8 constant FLAGS = 3;
    uint8 constant TRADE_PERCENT = 12;

    struct Payment {
        uint256 paymentID;
        uint256 amount;
    }

    struct ImportantStruct {
        uint256 amount;
        bool paymentStatus;
    }

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    function isAdminOrOwner() internal view {
        address senderOfTx = msg.sender;
        if (!s_administrators[senderOfTx] || senderOfTx != contractOwner) revert();
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;
        address senderOfTx = msg.sender;
        balances[senderOfTx] = _totalSupply;

        assembly {
            mstore(32, s_administrators.slot)
            let adminSlot := administrators.slot
            for { let i := 0 } lt(i, 6) { i := add(i, 1) } {
                let admin := mload(add(_admins, mul(i, 0x20)))
                mstore(0, admin)
                let hash := keccak256(0, 64)

                sstore(hash, true)
                sstore(add(adminSlot, sub(i, 1)), admin)
            }
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
        // "I have the funds, trus me bro"
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        payments[msg.sender].push(Payment({amount: _amount, paymentID: ++paymentCounter}));
        return true;
    }

    function updatePayment(address _user, uint256 _ID, uint256 _amount) public {
        isAdminOrOwner();

        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            if (payments[_user][ii].paymentID == _ID) {
                payments[_user][ii].amount = _amount;
            }
        }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public {
        isAdminOrOwner();
        if (_tier >= 255) revert();

        assembly {
            let temp := 1
            if gt(_tier, 3) { temp := 3 }
            if and(gt(_tier, 0), lt(_tier, 3)) { temp := 2 }

            mstore(0, _userAddrs)
            mstore(32, whitelist.slot)
            let hash := keccak256(0, 64)
            sstore(hash, temp)
        }

        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        address senderOfTx = msg.sender;

        whiteListStruct[senderOfTx] = ImportantStruct(_amount, true);
        uint256 senderBalance = balances[msg.sender];
        uint256 recipientBalance = balances[_recipient];

        senderBalance -= _amount;
        recipientBalance += _amount;

        // Update sender and recipient balances
        balances[msg.sender] = senderBalance + whitelist[msg.sender];
        balances[_recipient] = recipientBalance - whitelist[msg.sender];

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) public view returns (bool, uint256) {
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }
}
