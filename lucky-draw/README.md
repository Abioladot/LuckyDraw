# LuckyDraw

A comprehensive randomized prize distribution smart contract that enables fair and transparent lottery-style competitions with multiple prize tiers, provably fair randomness, and automated prize distribution.

## Overview

LuckyDraw revolutionizes online lotteries and prize competitions by providing a completely transparent, blockchain-based solution. Using deterministic randomness from future block numbers, every draw is provably fair and verifiable by all participants.

## Key Features

- **Provably Fair Randomness**: Uses future block numbers for unpredictable, verifiable winner selection
- **Multi-Tier Prize System**: Configure up to 10 different prize levels per draw
- **Flexible Entry System**: Variable entry fees and multiple ticket purchases
- **Time-Based Competitions**: Configurable draw duration and automatic execution
- **Transparent Operations**: All draws, entries, and winners are publicly verifiable
- **Secure Prize Claims**: Winners must actively claim prizes with ownership verification
- **Comprehensive Analytics**: Track participation history and winnings across all draws

## How It Works

### Randomness & Fairness
- **Future Block Randomness**: Uses block numbers from 10 blocks after draw ends
- **Manipulation-Proof**: No one can predict or influence future block numbers
- **Verifiable Results**: All calculations are transparent and auditable
- **Equal Probability**: Each ticket has exactly equal chance of winning

### Prize Distribution
- **Percentage-Based**: Prizes calculated as percentages of total entry pool
- **Multiple Winners**: Support for multiple prize tiers in single draw
- **Automatic Calculation**: Smart contract handles all prize math
- **Secure Claims**: Prizes held in escrow until claimed by verified winners

## Core Functions

### Creating Draws
```clarity
(create-draw 
  "Community Fundraiser"     ;; Title
  u1000000                   ;; 1 STX entry fee
  u100                       ;; Max 100 participants
  u1440                      ;; 10 day duration
  (list u5000 u3000 u2000))  ;; 50%, 30%, 20% prizes
```

### Participating in Draws
```clarity
;; Enter draw with 5 tickets
(enter-draw u1 u5)

;; Check if you won
(get-participant-info u1 'SP1234...)
```

### Claiming Prizes
```clarity
;; Claim first place prize
(claim-prize u1 u0)
```

### Draw Management
- `execute-draw(draw-id)` - Execute completed draw and select winners
- `is-draw-ready-for-execution(draw-id)` - Check if draw can be executed
- `calculate-random-winner(draw-id, prize-tier)` - Preview winner calculation

## Usage Examples

### Community Fundraiser
Create a charity raffle with multiple prize levels:
- **Entry Fee**: 2 STX per ticket
- **Duration**: 2 weeks  
- **Prizes**: 60% first place, 25% second place, 15% third place
- **Max Participants**: 500

### Gaming Tournament
Prize pool distribution for esports competition:
- **Entry Fee**: 5 STX per player
- **Prizes**: 50% winner, 30% runner-up, 20% third place
- **Instant execution** after tournament completion

### Token Launch Event
Fair distribution event for new projects:
- **Entry Fee**: 1 STX minimum
- **Multiple tickets allowed** for larger chances
- **Community-driven** prize pool growth

## Security Features

### Entry Protection
- **Payment Verification**: Entry fees must be paid before participation
- **Double-Entry Prevention**: Each address can only enter once per draw
- **Maximum Limits**: Participant caps prevent contract overload

### Draw Security
- **Time-Lock Execution**: Draws cannot be executed early
- **Randomness Delay**: 10-block delay prevents manipulation
- **Immutable Results**: Winners cannot be changed after selection

### Prize Security
- **Ownership Verification**: Only winners can claim their prizes
- **Claim Protection**: Prevents double-claiming of prizes
- **Escrow System**: Prizes held securely in contract until claimed

## Prize Tier System

### Configuration
- **Up to 10 tiers** per draw
- **Percentage-based** distribution (must sum to 100%)
- **Flexible allocation** - any split ratio supported

### Examples
```clarity
;; Winner takes all
(list u10000)  ;; 100% to first place

;; Traditional lottery split  
(list u7000 u2000 u1000)  ;; 70%, 20%, 10%

;; Equal distribution
(list u3333 u3333 u3334)  ;; ~33.33% each
```

## Analytics & Statistics

### User Statistics
- **Draws Entered**: Total participation count
- **Amount Spent**: Lifetime entry fee payments  
- **Total Won**: Sum of all prize winnings
- **Success Rate**: Win percentage across all draws

### Draw Analytics
- **Participation Rate**: How quickly draws fill up
- **Prize Pool Growth**: Total amount collected per draw
- **Winner Distribution**: Analysis of prize claim rates

### Global Metrics
- **Total Draws**: Network-wide lottery activity
- **Prize Distribution**: Total amount paid to winners
- **Platform Growth**: Usage trends and adoption metrics

## Integration Guide

### For Developers
```clarity
;; Check draw status
(get-draw-info u1)

;; Monitor user activity  
(get-user-stats 'SP1234...)

;; Verify winner legitimacy
(get-winner-info u1 u0)
```

### For DApps
- **Wallet Integration**: Enable lottery participation in apps
- **Prize Notifications**: Alert users about winnings
- **History Tracking**: Show participation and prize history

## Risk Considerations

### For Participants
- **No Guaranteed Returns**: Lottery participation involves risk of loss
- **Prize Claims Required**: Winners must actively claim prizes
- **Time-Sensitive**: Some draws may have claim deadlines

### For Draw Creators
- **Prize Pool Commitment**: Must ensure sufficient funds for all prizes
- **Randomness Dependency**: Results depend on blockchain randomness
- **Regulatory Compliance**: Consider local gambling/lottery regulations

## Use Cases

### Fundraising
- **Charity Events**: Transparent community fundraising
- **Project Funding**: Crowdfunding with prize incentives
- **Emergency Relief**: Rapid donation collection with rewards

### Gaming & Entertainment
- **Tournament Prizes**: Esports and gaming competitions
- **Community Events**: Discord/Telegram group activities  
- **Prediction Markets**: Outcome-based prize distribution

### Marketing & Promotion
- **Brand Campaigns**: Customer engagement through prizes
- **Product Launches**: Token distribution events
- **Community Building**: Incentivize platform participation

### DeFi Integration  
- **Yield Distribution**: Farming reward lotteries
- **Governance Incentives**: DAO participation rewards
- **Protocol Revenue Sharing**: Community profit distribution

Perfect for Communities seeking transparent prize distribution, gaming platforms, fundraising organizations, marketing campaigns, and any application requiring fair randomized rewards with complete transparency and verifiability.