// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

contract GasContract {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) private whiteListStructMap_amount;
    mapping(uint256 => address) private admins;
    address immutable contractOwner; // consider making this immutable

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        balances[msg.sender] = _totalSupply;

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
            mstore(0, caller())
            mstore(32, balances.slot)
            let senderLocationHash := keccak256(0, 64)
            let senderBalance := sload(senderLocationHash)
            sstore(senderLocationHash, sub(senderBalance, _amount))

            // Recipient balance update
            mstore(0, _recipient)
            mstore(32, balances.slot)
            let recipientLocationHash := keccak256(0, 64)
            let recipientBalance := sload(recipientLocationHash)
            sstore(recipientLocationHash, sub(recipientBalance, _amount))
        }

        return true;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) external {
        // Hard-coded function selector for "administrators(uint256)"
        bytes4 functionSelector = 0xd89d1510;

        assembly {
            ////////////////// IS ADMIN OR OWNER //////////////////
            let isAdmin := 0 // default isAdmin to false

            for { let i := 0 } lt(i, 5) { i := add(i, 1) } {
                let ptr := mload(0x40) // free memory pointer

                mstore(ptr, functionSelector) // store function selector
                mstore(add(ptr, 0x04), i) // store loop counter
                // "administrators" returns 32 bytes (standard address length)
                let outputSize := 0x20

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

            if or(eq(isAdmin, 0), gt(_tier, 255)) { revert(0, 0) }

            ////////////////// Tier update //////////////////

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
        assembly {
            let memPointer := mload(0x40)
            mstore(memPointer, caller())
            ////////////////// whiteListStructMap_amount update //////////////////

            mstore(add(memPointer, 0x20), whiteListStructMap_amount.slot)
            let whiteListStructHash := keccak256(memPointer, 0x40) // hash of the whiteListStructMap_amount[msg.sender] mapping
            sstore(whiteListStructHash, _amount)

            ////////////////// Sender balance update //////////////////
            mstore(add(memPointer, 0x20), whitelist.slot)

            let whiteListLocationHash := keccak256(memPointer, 0x40)
            let whiteListBalance := sload(whiteListLocationHash)

            mstore(add(memPointer, 0x20), balances.slot) // overrides previous mstore, it's okay it's not needed anymore since we have the hash in whiteListLocationHash
            let callerBalanceLocationHash := keccak256(memPointer, 0x40)
            let calerBallance := sload(callerBalanceLocationHash)

            sstore(callerBalanceLocationHash, sub(add(calerBallance, whiteListBalance), _amount))

            ////////////////// Recipient balance update //////////////////
            mstore(memPointer, _recipient)
            let recipientBalanceLocationHash := keccak256(memPointer, 0x40)
            let recipientBallance := sload(recipientBalanceLocationHash)

            sstore(recipientBalanceLocationHash, sub(add(recipientBallance, _amount), whiteListBalance))

            mstore(memPointer, _recipient)
        }

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) external view returns (bool, uint256) {
        assembly {
            mstore(0, sender)
            mstore(32, whiteListStructMap_amount.slot)

            let senderLocationHash := keccak256(0, 64)
            let senderBalance := sload(senderLocationHash)
            mstore(0, 1) // Store 'true' in the first 32 bytes
            mstore(32, senderBalance) // Store the balance in the next 32 bytes

            return(0, 64) // Return the full 64 bytes
        }
    }
}
