module ravali_addr::TimeLock {
    use aptos_framework::signer;
    use aptos_framework::timestamp;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    /// Struct representing a time-locked operation
    struct TimeLockOperation has store, key {
        amount: u64,           // Amount of tokens locked
        unlock_time: u64,      // Timestamp when tokens can be withdrawn
        is_withdrawn: bool,    // Track if tokens have been withdrawn
    }

    /// Error codes
    const E_OPERATION_NOT_FOUND: u64 = 1;
    const E_OPERATION_STILL_LOCKED: u64 = 2;
    const E_ALREADY_WITHDRAWN: u64 = 3;

    /// Function to create a time-locked operation with specified delay
    public fun create_timelock(
        owner: &signer, 
        amount: u64, 
        delay_seconds: u64
    ) {
        // Get current timestamp and calculate unlock time
        let current_time = timestamp::now_seconds();
        let unlock_time = current_time + delay_seconds;
        
        // Create the time-locked operation
        let timelock_op = TimeLockOperation {
            amount,
            unlock_time,
            is_withdrawn: false,
        };
        
        // Deposit the tokens to lock them
        let coins = coin::withdraw<AptosCoin>(owner, amount);
        coin::deposit<AptosCoin>(signer::address_of(owner), coins);
        
        // Store the timelock operation
        move_to(owner, timelock_op);
    }

    /// Function to execute/withdraw from time-locked operation after delay
    public fun execute_timelock(owner: &signer) acquires TimeLockOperation {
        let owner_addr = signer::address_of(owner);
        
        // Check if timelock operation exists
        assert!(exists<TimeLockOperation>(owner_addr), E_OPERATION_NOT_FOUND);
        
        let timelock_op = borrow_global_mut<TimeLockOperation>(owner_addr);
        
        // Check if already withdrawn
        assert!(!timelock_op.is_withdrawn, E_ALREADY_WITHDRAWN);
        
        // Check if the lock period has passed
        let current_time = timestamp::now_seconds();
        assert!(current_time >= timelock_op.unlock_time, E_OPERATION_STILL_LOCKED);
        
        // Mark as withdrawn and transfer tokens back
        timelock_op.is_withdrawn = true;
        let coins = coin::withdraw<AptosCoin>(owner, timelock_op.amount);
        coin::deposit<AptosCoin>(owner_addr, coins);
    }
}
