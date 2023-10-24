# GAS OPTIMSATION GAME

Clone <a href="https://github.com/ExtropyIO/GasOptimisationFoundry">this repo</a>.

- Your task is to edit and optimise the Gas.sol contract.
- You cannot edit the tests &
- All the tests must pass.
- You can change the functionality of the contract as long as the tests pass.
- Try to get the gas usage as low as possible.

## To run tests & gas report

Run: `forge test --gas-report`

## Stats

- Initial deployment cost: 2,541,445 gas
- Optimized deployment cost: 330,736 gas
- Gas reduction: 87%
- Gas saved: 2,210,709 gas

![Screenshot 2023-10-24 at 16 32 49](https://github.com/UrbanWill/foundry-gas-optimization/assets/47801291/ef4d7edb-f01f-4e5f-9aff-9d40758cf668)

## Approach

- Optimized deployment cost by using assembly and YUL
- Removed duplicated, unreachable and/or inefficient code
- Utilized sol2uml to analyze and pack storage variables in an efficient manner
