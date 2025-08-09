module ravali_addr::TimeLock {
    use aptos_framework::signer;
    use aptos_framework::timestamp;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;


    struct TimeLockOperation has store, key {
        amount: u64,          
        unlock_time: u64,     
        is_withdrawn: bool,   
    }

    
    const E_OPERATION_NOT_FOUND: u64 = 1;
    const E_OPERATION_STILL_LOCKED: u64 = 2;
    const E_ALREADY_WITHDRAWN: u64 = 3;

   
    public fun create_timelock(
        owner: &signer, 
        amount: u64, 
        delay_seconds: u64
    ) {
       
        let current_time = timestamp::now_seconds();
        let unlock_time = current_time + delay_seconds;
        
        
        let timelock_op = TimeLockOperation {
            amount,
            unlock_time,
            is_withdrawn: false,
        };
        
       
        let coins = coin::withdraw<AptosCoin>(owner, amount);
        coin::deposit<AptosCoin>(signer::address_of(owner), coins);
        

        move_to(owner, timelock_op);
    }

   
    public fun execute_timelock(owner: &signer) acquires TimeLockOperation {
        let owner_addr = signer::address_of(owner);
        
       
        assert!(exists<TimeLockOperation>(owner_addr), E_OPERATION_NOT_FOUND);
        
        let timelock_op = borrow_global_mut<TimeLockOperation>(owner_addr);
        
      
        assert!(!timelock_op.is_withdrawn, E_ALREADY_WITHDRAWN);
        
       
        let current_time = timestamp::now_seconds();
        assert!(current_time >= timelock_op.unlock_time, E_OPERATION_STILL_LOCKED);
        
       
        timelock_op.is_withdrawn = true;
        let coins = coin::withdraw<AptosCoin>(owner, timelock_op.amount);
        coin::deposit<AptosCoin>(owner_addr, coins);
    }
}

