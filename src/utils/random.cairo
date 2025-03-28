use core::traits::Into;
use core::box::BoxTrait;

fn pseudo_seed() -> (u128, u128, u128, u128) {
    let txinfo = starknet::get_tx_info().unbox();
    let tx: u256 = txinfo.transaction_hash.into();

    let blockInfo = starknet::get_block_info().unbox();
    let blockTimestamp: u128 = blockInfo.block_timestamp.into();
    let blockNumber: u128 = blockInfo.block_number.into();

    (tx.low, blockTimestamp / 2 + blockNumber, blockTimestamp, tx.low / 2 + blockNumber)
}


fn random(seed: u128, num: u32) -> u32 {
    let result = seed % num.into();
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
