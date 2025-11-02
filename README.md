 Usage Incentive Smart Contract

This Clarity smart contract implements a fee rebate system for Stacks users. Users pay fees to the contract, and once their cumulative payments reach a configurable threshold, they can claim a rebate. The contract owner can adjust parameters and withdraw funds.

 Features

- Fee Recording: Users call `pay-fee` to transfer STX to the contract. Their payments are tracked.
- Rebate Claiming: When a user's total paid fees reach the threshold, they can claim a rebate. The rebate is calculated as `floor(total_paid * rebate_rate / 100)`.
- Configurable Parameters: The contract owner can set the fee threshold and rebate rate.
- Owner Withdrawals: The owner can withdraw STX from the contract to a specified address.

 Functions

 Read-Only

- `get-owner`: Returns the contract owner.
- `get-fee-threshold`: Returns the current fee threshold.
- `get-rebate-rate`: Returns the current rebate rate.
- `get-total-paid (addr)`: Returns the total paid by a user.
- `get-contract-balance`: Returns the contract's STX balance.

 Public

- `pay-fee (amount)`: Pay STX to the contract and record the payment.
- `claim-rebate`: Claim a rebate if eligible.
- `set-threshold (new-threshold)`: Owner sets the fee threshold.
- `set-rebate-rate (new-rate)`: Owner sets the rebate rate.
- `owner-withdraw (to, amount)`: Owner withdraws STX to an address.

 Error Codes

- `ERR-NOT-OWNER (u100)`: Caller is not the contract owner.
- `ERR-NOT-ELIGIBLE (u101)`: User is not eligible to claim a rebate.
- `ERR-TRANSFER-FAILED (u102)`: STX transfer failed.
- `ERR-CONTRACT-INSUFFICIENT (u103)`: Contract has insufficient balance.
- `ERR-USER-NOT-FOUND (u104)`: User record not found.

 Usage

1. **Deploy the contract** to the Stacks blockchain.
2. **Users call `pay-fee`** to pay fees and accumulate rebate eligibility.
3. **Users call `claim-rebate`** when eligible to receive their rebate.
4. **Owner can adjust parameters** and withdraw funds as needed.

 Example

```clarity
(pay-fee u500)          ;; User pays 500 micro-STX
(claim-rebate)          ;; User claims rebate if eligible
(set-threshold u2000)   ;; Owner sets new threshold
(set-rebate-rate u15)   ;; Owner sets rebate rate to 15%
(owner-withdraw 'SP... u10000) ;; Owner withdraws 10,000 micro-STX
```

 License

MIT License
