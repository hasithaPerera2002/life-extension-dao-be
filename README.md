# Life Extension DAO – Solidity contracts

Solidity project that implements the contracts matching the frontend ABIs (AddressManager, Governance, Members, Payouts, Proposal).

## Setup

```bash
npm install
npm run compile
```

## Scripts

- `npm run compile` – compile contracts
- `npm run test` – run tests
- `npm run deploy:local` – deploy to local Hardhat network
- `npm run clean` – clean artifacts and cache

## Contract layout

- **AddressManager** – holds addresses of Governance, Members, Proposal, Payouts; `setContracts` wires them.
- **Governance** – voting, execute proposal, claim; uses Member and Proposal contracts.
- **Members** – join DAO, add insurance, proposals; member and insurance storage.
- **Payouts** – payout data and eligibility; used by Governance for claims.
- **Proposal** – create/vote/execute proposals; uses Governance and Members.

Interfaces and shared enums live under `contracts/interfaces/` and `contracts/libraries/`.

## ABIs

After `npm run compile`, ABIs are in `artifacts/contracts/`. These match the frontend consumption in `life-extension-dao-fe`.
