use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

use cosmwasm_std::{Addr, Timestamp};
use cw_storage_plus::Item;

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, JsonSchema)]
pub struct Config {
    /// Voting window period
    pub voting_window: u64,
    /// Voting token contract address
    pub voting_token: Addr,
    /// Owner address
    pub owner: Addr,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, JsonSchema)]
pub struct Proposal {
    /// Proposer address
    pub proposer: Addr,
    /// Timestamp of proposal
    pub timestamp: Timestamp,
}

pub const CONFIG: Item<Config> = Item::new("config");
pub const PROPOSAL: Item<Proposal> = Item::new("proposal");
