# PlayChoice

PlayChoice is a player-driven governance system for game modifications and community events built on the Stacks blockchain. This smart contract enables decentralized decision-making for gaming communities through a transparent voting mechanism.

## Overview

PlayChoice empowers gaming communities to democratically govern game modifications, community events, and rule changes. Players can create proposals, vote on initiatives, and execute community decisions through a robust smart contract system.

## Features

- **Player Registration**: Community members can register to participate in governance
- **Proposal Creation**: Registered players can create governance proposals with stake requirements
- **Democratic Voting**: Weighted voting system based on community participation
- **Proposal Execution**: Automatic execution of passed proposals after voting period
- **Participation Tracking**: Dynamic voting power that increases with engagement
- **Multiple Proposal Types**: Support for game modifications, events, and rule changes
- **Stake-based Proposals**: Minimum stake requirement prevents spam proposals
- **Time-locked Voting**: Fixed voting periods ensure fair participation

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity 2.5
- **Epoch**: 2.5
- **Minimum Stake**: 1 STX (1,000,000 microSTX)
- **Voting Period**: 1,000 blocks (~1 week)
- **Participation Threshold**: 10% of registered players

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for local development
- Node.js 16+ for running tests
- Stacks wallet for deployment

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd PlayChoice
```

2. Install dependencies:
```bash
cd PlayChoice_contract
npm install
```

3. Run tests:
```bash
npm test
```

4. Watch mode for development:
```bash
npm run test:watch
```

## Usage Examples

### Player Registration

```clarity
;; Register as a player to participate in governance
(contract-call? .PlayChoice register-player)
```

### Creating a Proposal

```clarity
;; Create a proposal for a game modification
(contract-call? .PlayChoice create-proposal
    "Add New Game Mode"
    "Proposal to add battle royale mode to the game with new mechanics and rewards"
    "game-mod"
    none
    u1000000) ;; 1 STX stake
```

### Voting on Proposals

```clarity
;; Vote yes on proposal ID 1
(contract-call? .PlayChoice vote-on-proposal u1 true)

;; Vote no on proposal ID 1
(contract-call? .PlayChoice vote-on-proposal u1 false)
```

### Executing Proposals

```clarity
;; Execute proposal after voting period ends
(contract-call? .PlayChoice execute-proposal u1)
```

## Contract Functions

### Public Functions

#### `register-player()`
Registers the caller as a player in the governance system.
- **Returns**: `(ok true)` on success
- **Errors**: `ERR_UNAUTHORIZED` if already registered

#### `create-proposal(title, description, proposal-type, target-contract, stake)`
Creates a new governance proposal.
- **Parameters**:
  - `title`: (string-ascii 100) - Proposal title
  - `description`: (string-ascii 500) - Detailed description
  - `proposal-type`: (string-ascii 50) - Type: "game-mod", "event", "rule-change"
  - `target-contract`: (optional principal) - Target contract for execution
  - `stake`: uint - Stake amount (minimum 1 STX)
- **Returns**: `(ok proposal-id)` on success
- **Errors**: Various validation errors

#### `vote-on-proposal(proposal-id, vote-yes)`
Casts a vote on an active proposal.
- **Parameters**:
  - `proposal-id`: uint - ID of the proposal
  - `vote-yes`: bool - true for yes, false for no
- **Returns**: `(ok true)` on success
- **Errors**: Various validation errors

#### `execute-proposal(proposal-id)`
Executes a proposal after the voting period ends.
- **Parameters**:
  - `proposal-id`: uint - ID of the proposal to execute
- **Returns**: `(ok {passed: bool, yes-votes: uint, no-votes: uint})`
- **Errors**: Various validation errors

#### `set-voting-power(player, power)` (Admin Only)
Sets voting power for a specific player (contract owner only).
- **Parameters**:
  - `player`: principal - Player address
  - `power`: uint - New voting power
- **Returns**: `(ok true)` on success
- **Errors**: `ERR_UNAUTHORIZED` if not contract owner

### Read-Only Functions

#### `get-proposal(proposal-id)`
Retrieves complete proposal details.

#### `get-vote(proposal-id, voter)`
Gets vote details for a specific voter and proposal.

#### `is-registered-player(player)`
Checks if a player is registered in the system.

#### `get-voting-power(player)`
Returns the voting power of a player.

#### `get-total-registered-players()`
Returns the total number of registered players.

#### `get-proposal-counter()`
Returns the current proposal counter.

#### `is-voting-active(proposal-id)`
Checks if voting is currently active for a proposal.

#### `get-proposal-results(proposal-id)`
Returns comprehensive results for a proposal.

## Error Codes

- `ERR_UNAUTHORIZED (100)`: Caller not authorized for this action
- `ERR_PROPOSAL_NOT_FOUND (101)`: Proposal does not exist
- `ERR_VOTING_CLOSED (102)`: Voting period has ended
- `ERR_ALREADY_VOTED (103)`: Player has already voted on this proposal
- `ERR_INVALID_PROPOSAL (104)`: Invalid proposal parameters
- `ERR_INSUFFICIENT_STAKE (105)`: Stake amount below minimum requirement
- `ERR_PROPOSAL_EXECUTED (106)`: Proposal has already been executed

## Deployment Guide

### Local Development (Devnet)

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contracts
```

### Testnet Deployment

1. Configure Testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments generate --devnet
clarinet deployments apply --devnet
```

### Mainnet Deployment

1. Configure Mainnet settings in `settings/Mainnet.toml`
2. Ensure thorough testing on testnet
3. Deploy with appropriate security measures:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## Security Considerations

### Access Control
- Player registration prevents unauthorized participation
- Stake requirements prevent spam proposals
- Time-locked voting periods ensure fair participation

### Economic Security
- Minimum stake requirement (1 STX) creates economic incentive for good behavior
- Progressive voting power rewards active community members
- Participation thresholds prevent minority rule

### Governance Security
- Proposals cannot be executed during voting period
- Double voting prevention mechanisms
- Transparent vote tracking and results

### Best Practices
- Always verify proposal details before voting
- Ensure sufficient community participation before execution
- Monitor proposal execution results
- Regular security audits recommended for production deployment

## Development

### Project Structure
```
PlayChoice_contract/
├── contracts/
│   └── PlayChoice.clar          # Main smart contract
├── tests/
│   └── PlayChoice.test.ts       # Test suite
├── settings/
│   ├── Devnet.toml             # Development configuration
│   ├── Testnet.toml            # Testnet configuration
│   └── Mainnet.toml            # Mainnet configuration
├── Clarinet.toml               # Project configuration
├── package.json                # Dependencies and scripts
└── vitest.config.js            # Test configuration
```

### Testing

Run the test suite:
```bash
npm test
```

Generate coverage report:
```bash
npm run test:report
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For questions, issues, or contributions, please refer to the project's issue tracker or community channels.