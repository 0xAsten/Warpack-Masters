use core::traits::Into;
use core::box::BoxTrait;

fn pseudo_seed() -> (felt252, felt252, felt252, felt252) {
    let txinfo = starknet::get_tx_info().unbox();
    let tx = txinfo.transaction_hash;
    let nonce = txinfo.nonce;

    let blockInfo = starknet::get_block_info().unbox();
    let blockTimestamp: felt252 = blockInfo.block_timestamp.into();
    let blockNumber: felt252 = blockInfo.block_number.into();

    (tx, nonce, blockTimestamp, blockNumber)
}


fn random(seed: felt252, num: usize) -> usize {
    let seed: u256 = seed.into();
    let result = seed.low % num.into();
    result.try_into().unwrap()
}


#[cfg(test)]
mod tests {
    use super::{pseudo_seed};
    use debug::PrintTrait;

    #[test]
    #[available_gas(100000)]
    fn test_grid_is_zero() {
        let (seed1, seed2, seed3, seed4) = pseudo_seed();
        seed1.print();
        seed2.print();
        seed3.print();
        seed4.print();
    }
}
