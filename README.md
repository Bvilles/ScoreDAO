# ScoreDAO - DAO Contribution Tracking System

DAOScore is a decentralized contribution tracking and reputation system built on Stacks blockchain using Clarity. It enables DAOs to track, verify, and reward member contributions transparently and fairly.

## Key Features

### Contribution Tracking
- Multiple contribution types with customizable weights
- Proof submission and verification system
- Timestamp-based tracking
- Automated reputation scoring

### Reputation System
- Token-based reputation (DAO-REP tokens)
- Level-based progression
- Historical contribution tracking
- Weighted scoring based on contribution type

### Verification & Rewards
- Multi-step verification process
- Automated reward distribution
- Transparent scoring mechanism
- Immutable contribution history

## Smart Contract Functions

### Administrative
- `add-contribution-type`: Add new types of contributions
- `verify-contribution`: Verify and score submitted contributions

### User Functions
- `submit-contribution`: Submit new contributions with proof
- `get-contributor-info`: View contributor statistics
- `get-reputation-balance`: Check reputation token balance

### Analytics
- Contribution history tracking
- Reputation score calculation
- Level progression system
- Activity metrics

## Implementation Guide

1. Deploy the smart contract
2. Set up contribution types:
   - Code contributions
   - Documentation
   - Community management
   - Governance participation
   - Technical reviews

3. Configure weights and minimum proof requirements
4. Set up verification workflow
5. Integrate with frontend dashboard

## Technical Stack

- Stacks Blockchain
- Clarity Smart Contracts
- React Frontend (recommended)
- IPFS for proof storage (optional)

## Getting Started

1. Clone the repository
2. Install Clarinet
3. Run tests:
   ```bash
   clarinet test
   ```
4. Deploy contract:
   ```bash
   clarinet deploy
   ```

## Security Considerations

- Multi-step verification process
- Owner-only administrative functions
- Proof requirements for contributions
- Rate limiting on submissions

## Example Contribution Types

1. Code Contributions (Weight: 100)
   - Pull Request links
   - Commit hashes
   - Review comments

2. Documentation (Weight: 75)
   - Document links
   - Version history
   - User feedback

3. Community Support (Weight: 50)
   - Forum posts
   - Support tickets
   - Workshop materials

## Level System

- Level 1: 0-99 points
- Level 2: 100-499 points
- Level 3: 500-999 points
- Level 4: 1000+ points

## Contributing

We welcome contributions! Please read our contributing guidelines before submitting pull requests.

