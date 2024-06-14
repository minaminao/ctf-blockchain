use cosmwasm_schema::cw_serde;
use cosmwasm_std::{Addr, Timestamp, Uint128};
use cw_storage_plus::{Item, Map};

#[cw_serde]
pub struct Lockup {
    /// Unique lockup identifier
    pub id: u64,
    /// Owner address
    pub owner: Addr,
    /// Locked amount
    pub amount: Uint128,
    /// Timestamp when the lockup can be withdrawn
    pub release_timestamp: Timestamp,
}

pub const LAST_ID: Item<u64> = Item::new("lock_id");
pub const LOCKUPS: Map<u64, Lockup> = Map::new("lockups");
