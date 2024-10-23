# ScoreDAO - Decentralized Contribution Tracking System

ScoreDAO is a decentralized contribution tracking and reputation system built on the Stacks blockchain. It enables DAOs to track, verify, and reward member contributions transparently and fairly.

## Key Features

### Contribution Tracking
- Multiple contribution types with customizable weights
- Proof submission and verification system
- Transparent scoring mechanism
- Automated reputation tracking

### Reputation System
- Score Token (SCORE) for reputation tracking
- Level-based progression system
- Historical contribution records
- Weighted scoring based on contribution type

### Security Features
- Input validation for all operations
- Owner-only administrative functions
- Secure proof verification
- Rate limiting and score caps

## Smart Contract Functions

### Administrative
- `add-contribution-type`: Add new types of contributions with weights
- `verify-contribution`: Verify and score submitted contributions

### User Functions
- `submit-contribution`: Submit new contributions with proof
- `get-contributor-info`: View contributor statistics
- `get-reputation-balance`: Check SCORE token balance

## Technical Implementation

### Contribution Types
Each contribution type includes:
- Name (max 50 characters)
- Weight (1-100)
- Minimum proof requirement
- Verification criteria

### Scoring System
- Base scores: 0-100
- Weight multipliers
- Level thresholds:
  - Level 1: 0-99 points
  - Level 2: 100-499 points
  - Level 3: 500-999 points
  - Level 4: 1000+ points

### Security Measures
- Input validation for all parameters
- Proof length and content verification
- Score range validation
- Administrative access control

## Getting Started

1. Deploy the contract:
```bash
clarinet contract deploy
```

2. Initialize contribution types:
```clarity
(contract-call? .scoredao add-contribution-type "Code Review" u50 u100)
```

3. Submit contribution:
```clarity
(contract-call? .scoredao submit-contribution u1 "https://github.com/...")
```

## Development

### Prerequisites
- Clarinet
- Stacks CLI
- Node.js (for frontend development)

### Testing
Run the test suite:
```bash
clarinet test
```

## Integration Guide

### Frontend Integration
1. Connect to Stacks network
2. Import contract ABI
3. Implement wallet connection
4. Create submission forms
5. Display reputation scores

### API Endpoints
- Get contributor info
- Submit contributions
- Check reputation
- View contribution history

## Contributing

We welcome contributions! Please read our contributing guidelines and submit pull requests.


