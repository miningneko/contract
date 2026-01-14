// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title 0xNEKO
 * @dev Minable ERC20 Token using NekoCycle PoW.
 *      Features: ChainID Binding, ASERT Difficulty, Smooth Emission.
 */
contract OxNEKO is ERC20, ReentrancyGuard {
    // ==========================================
    // Constants
    // ==========================================
    uint256 public constant CYCLE_LENGTH = 42;
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1 Billion
    uint256 public constant TARGET_BLOCK_TIME = 60; // 1 minute target
    uint256 public constant EMISSION_SPEED_FACTOR = 20;
    uint256 public constant MIN_REWARD = 10**17; // 0.1 NEKO tail emission
    
    // ASERT Constants
    uint256 public constant ASERT_HALF_LIFE = 2880; // blocks (~2 days at target rate)
    uint256 public constant MAX_TARGET = 2**254;
    uint256 public constant MIN_TARGET = 2**200;
    
    uint256 public immutable DEPLOY_CHAIN_ID;
    uint256 public immutable DEPLOY_TIMESTAMP;

    // ==========================================
    // State Variables
    // ==========================================
    bytes32 public challengeNumber;
    uint256 public epochCount;
    uint256 public tokensMinted;
    
    // ASERT State
    uint256 public miningTarget;
    uint256 public anchorTime;
    uint256 public anchorEpoch;
    uint256 public anchorTarget;

    // ==========================================
    // Events
    // ==========================================
    event Mint(
        address indexed miner, 
        uint256 reward, 
        uint256 indexed epochCount, 
        bytes32 newChallenge, 
        uint256 newTarget
    );
    event DifficultyAdjusted(uint256 oldTarget, uint256 newTarget, uint256 epochCount);

    // ==========================================
    // Errors (Gas efficient)
    // ==========================================
    error InvalidSolutionLength();
    error MaxSupplyReached();
    error HashAboveTarget();
    error CycleBroken(uint256 index);
    error CycleNotClosed();

    constructor() ERC20("0xNEKO", "0xNEKO") {
        DEPLOY_CHAIN_ID = block.chainid;
        DEPLOY_TIMESTAMP = block.timestamp;
        
        // Use multiple entropy sources for initial challenge
        challengeNumber = keccak256(abi.encode(
            block.timestamp, 
            block.chainid, 
            address(this),
            block.prevrandao
        ));
        
        // ASERT Anchor
        anchorTime = block.timestamp;
        anchorEpoch = 0;
        anchorTarget = 2**232; // Initial target
        miningTarget = anchorTarget;
    }

    // ==========================================
    // Mining Core
    // ==========================================

    function mint(uint256 nonce, uint256[] calldata solution) external nonReentrant {
        // Use custom errors for gas efficiency
        if (solution.length != CYCLE_LENGTH) revert InvalidSolutionLength();
        if (tokensMinted >= MAX_SUPPLY) revert MaxSupplyReached();

        // 1. Compute solution hash with all binding parameters
        bytes32 solutionHash = keccak256(abi.encode(
            challengeNumber,  // Bind to current challenge
            solution, 
            msg.sender, 
            nonce, 
            block.chainid
        ));
        
        // 2. Verify difficulty target
        if (uint256(solutionHash) >= miningTarget) revert HashAboveTarget();

        // 3. Verify Cycle
        bytes32 localChallenge = keccak256(abi.encode(
            challengeNumber, 
            msg.sender, 
            nonce,
            block.chainid
        ));
        _verifyCycle(localChallenge, solution);

        // 4. Calculate reward BEFORE state changes
        uint256 reward = _calculateReward();

        // 5. Update State (Effects)
        unchecked {
            // Safe: reward is bounded by remaining supply
            tokensMinted += reward;
            epochCount++;
        }

        // Update Challenge (new challenge = hash of solution)
        challengeNumber = solutionHash;

        // ASERT Difficulty Adjustment
        uint256 oldTarget = miningTarget;
        _adjustDifficultyASERT();

        // 6. Reward (Interaction)
        _mint(msg.sender, reward);

        emit Mint(msg.sender, reward, epochCount, challengeNumber, miningTarget);
        
        if (oldTarget != miningTarget) {
            emit DifficultyAdjusted(oldTarget, miningTarget, epochCount);
        }
    }

    // ==========================================
    // NekoCycle Logic
    // ==========================================

    function _verifyCycle(bytes32 root, uint256[] calldata solution) internal pure {
        uint256 firstU;
        uint256 prevV;

        for (uint256 i = 0; i < CYCLE_LENGTH;) {
            (uint256 u, uint256 v) = _branchingHash(root, solution[i]);
            
            if (i == 0) {
                firstU = u;
            } else {
                if (u != prevV) revert CycleBroken(i);
            }
            prevV = v;
            
            unchecked { ++i; }
        }
        if (prevV != firstU) revert CycleNotClosed();
    }

    function _branchingHash(bytes32 root, uint256 edgeIndex) internal pure returns (uint256 u, uint256 v) {
        uint256 state = uint256(keccak256(abi.encode(root, edgeIndex)));
        
        unchecked {
            for (uint256 i = 0; i < 8; ++i) {
                uint256 mode = state & 0x7; 
                
                if (mode == 0) {
                    state = uint256(keccak256(abi.encode(state)));
                } else if (mode == 1) {
                    state = state ^ (state << 13);
                } else if (mode == 2) {
                    state = state + 0x123456789;
                } else if (mode == 3) {
                    state = (state >> 5) | (state << 251);
                } else if (mode == 4) {
                    state = state * 0x1A2B3C;
                } else if (mode == 5) {
                    state = ~state;
                } else {
                    state = state ^ 0xFF00FF00FF00FF00;
                }
                state ^= i;
            }
        }

        u = uint256(keccak256(abi.encode(state, uint8(0)))) & 0xFFFFFFFFFFFFFFFF;
        v = uint256(keccak256(abi.encode(state, uint8(1)))) & 0xFFFFFFFFFFFFFFFF; 
    }

    // ==========================================
    // ASERT Difficulty Adjustment (Exponential)
    // ==========================================

    function _adjustDifficultyASERT() internal {
        uint256 currentTime = block.timestamp;
        uint256 timeDelta = currentTime - anchorTime;
        uint256 epochDelta = epochCount - anchorEpoch;
        
        // Edge case: first block after anchor
        if (epochDelta == 0) return;
        
        // Ideal time for epochDelta blocks
        uint256 idealTime = epochDelta * TARGET_BLOCK_TIME;
        uint256 halfLifeSeconds = ASERT_HALF_LIFE * TARGET_BLOCK_TIME;
        
        uint256 newTarget;
        
        if (timeDelta >= idealTime) {
            // Slower than expected -> easier (increase target)
            uint256 excessTime = timeDelta - idealTime;
            
            uint256 shifts = excessTime / halfLifeSeconds;
            uint256 remainder = excessTime % halfLifeSeconds;
            
            // Calculate maximum safe shift to prevent overflow
            // For anchorTarget = 2^232, max safe shift is 256 - 232 = 24
            // We calculate: maxShift = 256 - log2(anchorTarget)
            uint256 maxSafeShift = _maxSafeLeftShift(anchorTarget);
            
            if (shifts >= maxSafeShift) {
                // Would overflow, cap at MAX_TARGET
                newTarget = MAX_TARGET;
            } else {
                // Safe to shift
                unchecked {
                    newTarget = anchorTarget << shifts;
                }
                
                // Apply fractional adjustment: target *= (1 + remainder/halfLife * ln(2))
                // ln(2) ≈ 0.693 ≈ 693/1000
                // Use unchecked for fractional math, then bounds check
                unchecked {
                    uint256 fractionalAdjust = (newTarget / 1000) * 693 * remainder / halfLifeSeconds;
                    
                    if (newTarget > MAX_TARGET - fractionalAdjust) {
                        newTarget = MAX_TARGET;
                    } else {
                        newTarget += fractionalAdjust;
                    }
                }
            }
        } else {
            // Faster than expected -> harder (decrease target)
            uint256 deficitTime = idealTime - timeDelta;
            
            uint256 shifts = deficitTime / halfLifeSeconds;
            uint256 remainder = deficitTime % halfLifeSeconds;
            
            // Right shift is always safe (just becomes 0)
            if (shifts >= 256) {
                newTarget = MIN_TARGET;
            } else {
                unchecked {
                    newTarget = anchorTarget >> shifts;
                }
                
                // Apply fractional adjustment
                unchecked {
                    uint256 fractionalAdjust = (newTarget / 1000) * 693 * remainder / halfLifeSeconds;
                    
                    if (fractionalAdjust >= newTarget) {
                        newTarget = MIN_TARGET;
                    } else {
                        newTarget -= fractionalAdjust;
                    }
                }
            }
        }
        
        // Enforce bounds
        if (newTarget > MAX_TARGET) newTarget = MAX_TARGET;
        if (newTarget < MIN_TARGET) newTarget = MIN_TARGET;
        
        miningTarget = newTarget;
        
        // Update anchor periodically to maintain precision
        if (epochCount % 100 == 0) {
            anchorTime = currentTime;
            anchorEpoch = epochCount;
            anchorTarget = newTarget;
        }
    }
    
    /// @dev Calculate maximum safe left shift for a value without overflow
    function _maxSafeLeftShift(uint256 value) internal pure returns (uint256) {
        if (value == 0) return 256;
        
        // Count leading zeros using binary search
        uint256 n = 0;
        unchecked {
            if (value <= type(uint128).max) { n += 128; value <<= 128; }
            if (value <= type(uint64).max << 192) { n += 64; value <<= 64; }
            if (value <= type(uint32).max << 224) { n += 32; value <<= 32; }
            if (value <= type(uint16).max << 240) { n += 16; value <<= 16; }
            if (value <= type(uint8).max << 248) { n += 8; value <<= 8; }
            if (value <= 0x0F << 252) { n += 4; value <<= 4; }
            if (value <= 0x03 << 254) { n += 2; value <<= 2; }
            if (value <= 0x01 << 255) { n += 1; }
        }
        return n;
    }

    // ==========================================
    // Emission
    // ==========================================

    function _calculateReward() internal view returns (uint256) {
        uint256 remaining = MAX_SUPPLY - tokensMinted;
        
        // Smooth decay: reward = remaining >> EMISSION_SPEED_FACTOR
        uint256 reward = remaining >> EMISSION_SPEED_FACTOR;
        
        // Tail emission floor
        if (reward < MIN_REWARD) {
            reward = remaining < MIN_REWARD ? remaining : MIN_REWARD;
        }
        
        return reward;
    }

    function getMiningReward() external view returns (uint256) {
        return _calculateReward();
    }

    // ==========================================
    // Complete API Interface
    // ==========================================

    /// @notice Get current challenge hash that miners must solve against
    function getChallengeNumber() external view returns (bytes32) {
        return challengeNumber;
    }

    /// @notice Get current mining difficulty target (lower = harder)
    function getMiningTarget() external view returns (uint256) {
        return miningTarget;
    }

    /// @notice Get all mining-related info in one call (gas efficient for miners)
    /// @return challenge Current challenge hash
    /// @return target Current difficulty target
    /// @return reward Current block reward
    /// @return epoch Total blocks mined so far
    /// @return supply Total tokens minted
    /// @return remaining Tokens remaining to be minted
    function getBlockInfo() external view returns (
        bytes32 challenge,
        uint256 target,
        uint256 reward,
        uint256 epoch,
        uint256 supply,
        uint256 remaining
    ) {
        uint256 r = _calculateReward();
        return (
            challengeNumber, 
            miningTarget, 
            r, 
            epochCount,
            tokensMinted,
            MAX_SUPPLY - tokensMinted
        );
    }

    /// @notice Get ASERT difficulty adjustment parameters
    /// @return currentTarget Current mining target
    /// @return anchor The anchor target used for ASERT calculation
    /// @return anchorEpochNum Epoch number when anchor was set
    /// @return anchorTimestamp Timestamp when anchor was set
    /// @return halfLife Half-life constant in blocks
    function getDifficultyInfo() external view returns (
        uint256 currentTarget,
        uint256 anchor,
        uint256 anchorEpochNum,
        uint256 anchorTimestamp,
        uint256 halfLife
    ) {
        return (miningTarget, anchorTarget, anchorEpoch, anchorTime, ASERT_HALF_LIFE);
    }

    /// @notice Get token economics info
    /// @return maxSupply Maximum token supply
    /// @return minted Total tokens minted so far
    /// @return currentReward Current block reward
    /// @return minReward Minimum tail emission reward
    /// @return emissionFactor Speed factor for emission decay
    function getEconomicsInfo() external view returns (
        uint256 maxSupply,
        uint256 minted,
        uint256 currentReward,
        uint256 minReward,
        uint256 emissionFactor
    ) {
        return (MAX_SUPPLY, tokensMinted, _calculateReward(), MIN_REWARD, EMISSION_SPEED_FACTOR);
    }

    /// @notice Get chain binding info
    /// @return deployChainId Chain ID this contract was deployed on
    /// @return currentChainId Current chain ID (for verification)
    /// @return deployTime Deployment timestamp
    function getChainInfo() external view returns (
        uint256 deployChainId,
        uint256 currentChainId,
        uint256 deployTime
    ) {
        return (DEPLOY_CHAIN_ID, block.chainid, DEPLOY_TIMESTAMP);
    }

    /// @notice Calculate mining difficulty as human-readable number
    /// @return difficulty Inverse of target, higher = harder
    function getDifficulty() external view returns (uint256) {
        // difficulty = 2^256 / target (approximately)
        if (miningTarget == 0) return type(uint256).max;
        return type(uint256).max / miningTarget;
    }

    /// @notice Estimate hashrate from recent blocks (informational only)
    /// @return estimatedHashrate Estimated network hashrate
    /// @return timeSinceAnchor Seconds since last anchor
    /// @return blocksSinceAnchor Blocks mined since anchor
    function getNetworkStats() external view returns (
        uint256 estimatedHashrate,
        uint256 timeSinceAnchor,
        uint256 blocksSinceAnchor
    ) {
        timeSinceAnchor = block.timestamp - anchorTime;
        blocksSinceAnchor = epochCount - anchorEpoch;
        
        if (timeSinceAnchor == 0 || blocksSinceAnchor == 0) {
            return (0, timeSinceAnchor, blocksSinceAnchor);
        }
        
        // Estimated hashes = difficulty * blocks / time
        uint256 difficulty = type(uint256).max / miningTarget;
        estimatedHashrate = (difficulty * blocksSinceAnchor) / timeSinceAnchor;
    }

    /// @notice Verify if a solution would be valid (for pre-submission checks)
    /// @param nonce The nonce used
    /// @param solution The 42-element cycle solution
    /// @return valid Whether the solution meets difficulty target
    /// @return solutionHash The computed solution hash
    function verifySolution(uint256 nonce, uint256[] calldata solution) external view returns (
        bool valid,
        bytes32 solutionHash
    ) {
        if (solution.length != CYCLE_LENGTH) return (false, bytes32(0));
        
        solutionHash = keccak256(abi.encode(
            challengeNumber,
            solution, 
            msg.sender, 
            nonce, 
            block.chainid
        ));
        
        valid = uint256(solutionHash) < miningTarget;
    }

    /// @notice Get the local challenge for a specific miner (for off-chain computation)
    /// @param miner Address of the miner
    /// @param nonce The nonce being used
    /// @return localChallenge The challenge hash to solve against
    function getLocalChallenge(address miner, uint256 nonce) external view returns (bytes32) {
        return keccak256(abi.encode(
            challengeNumber, 
            miner, 
            nonce,
            block.chainid
        ));
    }

    /// @notice Compute edge (u, v) for a given challenge and edge index (for off-chain cycle finding)
    /// @param root The local challenge hash
    /// @param edgeIndex The edge index to compute
    /// @return u First node of the edge
    /// @return v Second node of the edge
    function computeEdge(bytes32 root, uint256 edgeIndex) external pure returns (uint256 u, uint256 v) {
        return _branchingHash(root, edgeIndex);
    }

    /// @notice Get all protocol constants
    function getConstants() external pure returns (
        uint256 cycleLength,
        uint256 maxSupply,
        uint256 targetBlockTime,
        uint256 emissionSpeedFactor,
        uint256 minReward,
        uint256 asertHalfLife,
        uint256 maxTarget,
        uint256 minTarget
    ) {
        return (
            CYCLE_LENGTH,
            MAX_SUPPLY,
            TARGET_BLOCK_TIME,
            EMISSION_SPEED_FACTOR,
            MIN_REWARD,
            ASERT_HALF_LIFE,
            MAX_TARGET,
            MIN_TARGET
        );
    }
}
