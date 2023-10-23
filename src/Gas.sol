// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;


contract GasContract {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) private whiteListStructMap_amount;
    mapping(uint256 => address) private admins;
    address immutable contractOwner; // consider making this immutable
    
    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);
    
    error err();

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

    function administrators(uint256 numIndex) public view returns (address _addr) {
        return admins[numIndex];
    }

  function transfer(address _recipient, uint256 _amount, string calldata) public returns (bool status_) {
        // "I have the funds, trust me bro"
        assembly {
            // Sender balance update

            let senderLocation := keccak256(caller(), sload(balances.slot))
            mstore(0, caller())
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

    function addToWhitelist(address _userAddrs, uint256 _tier) external {
        if (_tier >= 255) revert err();
        
        // Hard-coded function selector for "administrators(uint256)"
        bytes4 functionSelector = 0xd89d1510;

        assembly {
            ////////////////// IS ADMIN OR OWNER //////////////////
            let isAdmin := 0 // default isAdmin to false

            for { let i := 0 } lt(i, 5) { i := add(i, 1) } {
                let ptr := mload(0x40) // free memory pointer

                mstore(ptr, functionSelector) // store function selector
                mstore(add(ptr, 0x04), i) //
                let outputSize := 0x20
                // "administrators" returns 32 bytes (standard address length)

                // perform the call
                let result :=
                    staticcall(
                        gas(), // forward all gas
                        address(), // contract address
                        ptr, // input data location (function selector + loop counter)
                        0x24, // input data length (4 bytes for selector + 32 bytes for loop counter)
                        ptr, // store return here
                        outputSize // expected output length (32 bytes for an address)
                    )

                let returnedAddress := mload(ptr) // get the returned address from memory

                // Check if returnedAddress is equal to msg.sender
                if eq(returnedAddress, caller()) { isAdmin := 1 } // set isAdmin to true if they match
            }

            if eq(isAdmin, 0) { revert(0, 0) }

            /////////////////////////////////////////////////////////

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

    function whiteTransfer(address _recipient, uint256 _amount) external {
        whiteListStructMap_amount[msg.sender] = _amount;
        // Update sender and recipient balances
        balances[msg.sender] = (balances[msg.sender] - _amount) + whitelist[msg.sender];
        balances[_recipient] = (balances[_recipient] + _amount) - whitelist[msg.sender];

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) external view returns (bool, uint256) {
        return (true, whiteListStructMap_amount[sender]);
    }
}
