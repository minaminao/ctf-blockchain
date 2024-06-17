use cosmwasm_schema::cw_serde;
use cosmwasm_std::{Addr, Uint128};
use cw_storage_plus::{Item, Map};

#[cw_serde]
pub struct Config {
    pub total_supply: Uint128,
}

#[cw_serde]
#[derive(Default)]
pub struct Balance {
    pub amount: Uint128,
}

pub const CONFIG: Item<Config> = Item::new("config");
pub const BALANCES: Map<&Addr, Balance> = Map::new("balances");
