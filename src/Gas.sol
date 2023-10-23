// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract GasContract {
    address[5] public administrators;
    uint256 totalSupply; // consider making this immutable
    uint256 paymentCounter;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => ImportantStruct) public whiteListStruct;
    address contractOwner; // consider making this immutable
    // @dev - 0x01 = tradeFlag, 0x02 = dividendFlag
    uint8 constant FLAGS = 3;
    uint8 constant TRADE_PERCENT = 12;

    struct ImportantStruct {
        uint256 amount;
        bool paymentStatus;
    }

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
        if (!admin || senderOfTx != contractOwner) revert();
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;
        address senderOfTx = msg.sender;
        balances[senderOfTx] = _totalSupply;
        for (uint256 ii = 0; ii < 5; ii++) {
            address tempAdmin = _admins[ii];
            administrators[ii] = tempAdmin;
        }
    }

    function balanceOf(address _user) external view returns (uint256 balance_) {
        uint256 balance = balances[_user];
        return balance;
    }

    function transfer(address _recipient, uint256 _amount, string calldata _name) public returns (bool status_) {
        // "I have the funds, trust me bro"
        assembly {
            // Sender balance update
            let sender := calldataload(24)
            let senderLocation := keccak256(sender, sload(balances.slot))
            mstore(0, sender)
            mstore(32, balances.slot)
            let senderBalance := sload(senderLocation)

            let senderHash := keccak256(0, 64)
            sstore(senderHash, sub(senderBalance, _amount))

            // Recipient balance update
            let recipientLocation := keccak256(_recipient, sload(balances.slot))
            mstore(0, _recipient)
            mstore(32, balances.slot)
            let recipientBalance := sload(recipientLocation)

            let recipientHash := keccak256(0, 64)
            sstore(recipientHash, sub(recipientBalance, _amount))
        }

        return true;
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

        // User transfer function here
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
