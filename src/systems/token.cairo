use starknet::ContractAddress;

// Standard ERC-20 interface compatible with Ekubo AMM
#[starknet::interface]
pub trait IERC20<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn decimals(self: @TContractState) -> u8;
    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
}

// Additional interface for mint/burn (used by storage bridge)
#[starknet::interface]
pub trait IItemToken<TContractState> {
    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn burn(ref self: TContractState, account: ContractAddress, amount: u256);
    fn get_item_id(self: @TContractState) -> u32;
    fn get_minter(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
pub mod ItemTokenContract {
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        decimals: u8,
        total_supply: u256,
        balances: LegacyMap<ContractAddress, u256>,
        allowances: LegacyMap<(ContractAddress, ContractAddress), u256>,
        minter: ContractAddress,
        item_id: u32,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        value: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        spender: ContractAddress,
        value: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        minter: ContractAddress,
        item_id: u32
    ) {
        self.name.write(name);
        self.symbol.write(symbol);
        self.decimals.write(0); // Items are non-divisible (0 decimals)
        self.total_supply.write(0);
        self.minter.write(minter);
        self.item_id.write(item_id);
    }

    // Standard ERC-20 implementation compatible with Ekubo AMM
    #[abi(embed_v0)]
    impl ERC20Impl of super::IERC20<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        fn decimals(self: @ContractState) -> u8 {
            self.decimals.read()
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account)
        }

        fn allowance(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> u256 {
            self.allowances.read((owner, spender))
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();
            self._transfer(sender, recipient, amount);
            true
        }

        fn transfer_from(ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            let current_allowance = self.allowances.read((sender, caller));
            assert(current_allowance >= amount, 'Insufficient allowance');
            
            // Update allowance
            self.allowances.write((sender, caller), current_allowance - amount);
            
            // Perform transfer
            self._transfer(sender, recipient, amount);
            true
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let owner = get_caller_address();
            self._approve(owner, spender, amount);
            true
        }
    }

    // Additional functions for mint/burn (used by storage bridge)
    #[abi(embed_v0)]
    impl ItemTokenImpl of super::IItemToken<ContractState> {
        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            assert(caller == self.minter.read(), 'Only minter can mint');
            
            let current_supply = self.total_supply.read();
            let current_balance = self.balances.read(recipient);
            
            self.total_supply.write(current_supply + amount);
            self.balances.write(recipient, current_balance + amount);
            
            // Emit Transfer event (from zero address = mint)
            self.emit(Event::Transfer(Transfer {
                from: starknet::contract_address_const::<0>(),
                to: recipient,
                value: amount
            }));
        }

        fn burn(ref self: ContractState, account: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            assert(caller == self.minter.read(), 'Only minter can burn');
            
            let current_balance = self.balances.read(account);
            assert(current_balance >= amount, 'Insufficient balance');
            
            let current_supply = self.total_supply.read();
            self.total_supply.write(current_supply - amount);
            self.balances.write(account, current_balance - amount);
            
            // Emit Transfer event (to zero address = burn)
            self.emit(Event::Transfer(Transfer {
                from: account,
                to: starknet::contract_address_const::<0>(),
                value: amount
            }));
        }

        fn get_item_id(self: @ContractState) -> u32 {
            self.item_id.read()
        }

        fn get_minter(self: @ContractState) -> ContractAddress {
            self.minter.read()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _transfer(ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) {
            assert(!sender.is_zero(), 'Transfer from zero address');
            assert(!recipient.is_zero(), 'Transfer to zero address');
            
            let sender_balance = self.balances.read(sender);
            assert(sender_balance >= amount, 'Insufficient balance');
            
            // Update balances
            self.balances.write(sender, sender_balance - amount);
            let recipient_balance = self.balances.read(recipient);
            self.balances.write(recipient, recipient_balance + amount);
            
            // Emit Transfer event
            self.emit(Event::Transfer(Transfer {
                from: sender,
                to: recipient,
                value: amount
            }));
        }

        fn _approve(ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256) {
            assert(!owner.is_zero(), 'Approve from zero address');
            assert(!spender.is_zero(), 'Approve to zero address');
            
            self.allowances.write((owner, spender), amount);
            
            // Emit Approval event
            self.emit(Event::Approval(Approval {
                owner,
                spender,
                value: amount
            }));
        }
    }
}

// Dispatcher traits for interacting with deployed token contracts
#[derive(Copy, Drop)]
pub struct ItemTokenDispatcher {
    pub contract_address: ContractAddress,
}

impl ItemTokenDispatcherImpl of super::IItemToken<ItemTokenDispatcher> {
    fn mint(ref self: ItemTokenDispatcher, recipient: ContractAddress, amount: u256) {
        // This would call the deployed contract
        // Implementation depends on how you want to handle dispatchers
    }

    fn burn(ref self: ItemTokenDispatcher, account: ContractAddress, amount: u256) {
        // This would call the deployed contract  
        // Implementation depends on how you want to handle dispatchers
    }

    fn get_item_id(self: @ItemTokenDispatcher) -> u32 {
        // This would call the deployed contract
        0 // Placeholder
    }

    fn get_minter(self: @ItemTokenDispatcher) -> ContractAddress {
        // This would call the deployed contract
        starknet::contract_address_const::<0>() // Placeholder
    }
} 