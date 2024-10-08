#[starknet::interface]
trait IAuction<T> {
    fn register_item(ref self: T, item_name: felt252);
    fn unregister_item(ref self: T, item_name: felt252);
    fn bid(ref self: T, item_name: felt252, amount: u256);
    fn get_highest_bidder(self: @T, item_name: felt252) -> u256;
    fn is_registered(self: @T, item_name: felt252) -> bool;
}


#[starknet::contract]
pub mod Auction {
    use super::{IAuction};
    use core::starknet::{
        get_caller_address, ContractAddress,
        storage::{Map, StorageMapReadAccess, StorageMapWriteAccess}
    };

    #[storage]
    pub struct Storage {
        bid: Map<felt252, u256>,
        register: Map<felt252, bool>,
        highest_bidder: Map<felt252, ContractAddress>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ItemRegistered: ItemRegistered,
        ItemUnregistered: ItemUnregistered,
        BidPlaced: BidPlaced,
    }

    #[derive(Drop, starknet::Event)]
    struct ItemRegistered {
        item_name: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct ItemUnregistered {
        item_name: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct BidPlaced {
        item_name: felt252,
        bidder: ContractAddress,
        amount: u256,
    }

    #[abi(embed_v0)]
    impl AuctionImpl of IAuction<ContractState> {
        fn register_item(ref self: ContractState, item_name: felt252) {
            assert(!self.register.read(item_name), 'Item already registered');
            self.register.write(item_name, true);
            self.emit(Event::ItemRegistered(ItemRegistered { item_name }));
        }

        fn unregister_item(ref self: ContractState, item_name: felt252) {
            assert(self.register.read(item_name), 'Item not registered');
            self.register.write(item_name, false);
            self.bid.write(item_name, 0);
            self.emit(Event::ItemUnregistered(ItemUnregistered { item_name }));
        }

        fn bid(ref self: ContractState, item_name: felt252, amount: u256) {
            assert(self.register.read(item_name), 'Item not registered');
            assert(amount > self.bid.read(item_name), 'Bid too low');

            let caller = get_caller_address();
            self.bid.write(item_name, amount);
            self.highest_bidder.write(item_name, caller);

            self.emit(Event::BidPlaced(BidPlaced { item_name, bidder: caller, amount }));
        }

        fn get_highest_bidder(self: @ContractState, item_name: felt252) -> u256 {
            self.bid.read(item_name)
        }

        fn is_registered(self: @ContractState, item_name: felt252) -> bool {
            self.register.read(item_name)
        }
    }
}
