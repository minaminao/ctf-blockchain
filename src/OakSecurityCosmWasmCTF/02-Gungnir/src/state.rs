use cosmwasm_schema::cw_serde;
use cosmwasm_std::{Addr, Timestamp, Uint128};
use cw_storage_plus::Map;

#[cw_serde]
#[derive(Default)]
pub struct UserInfo {
    /// Total tokens staked
    pub total_tokens: Uint128,
    /// User voting power
    pub voting_power: u128,
    /// Release time to withdraw staked tokens
    pub released_time: Timestamp,
}

pub const VOTING_POWER: Map<&Addr, UserInfo> = Map::new("voting_power");
