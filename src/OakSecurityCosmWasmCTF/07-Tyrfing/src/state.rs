use cosmwasm_std::{Addr, Uint128};
use cw_storage_plus::{Item, Map};

pub const OWNER: Item<Addr> = Item::new("address");

pub const THRESHOLD: Item<Uint128> = Item::new("config");

pub const BALANCES: Map<&Addr, Uint128> = Map::new("user_balances");
