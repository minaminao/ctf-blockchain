use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

use crate::error::ContractError;
use cosmwasm_std::{Addr, Storage, Uint128};
use cw_storage_plus::{Item, Map};

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, Eq, JsonSchema)]
pub struct State {
    /// Current owner
    pub current_owner: Addr,
    /// Proposed owner
    pub proposed_owner: Option<Addr>,
}

pub const STATE: Item<State> = Item::new("state");
pub const BALANCES: Map<&Addr, Uint128> = Map::new("user_balances");

pub fn assert_owner(store: &dyn Storage, sender: Addr) -> Result<(), ContractError> {
    let state = STATE.load(store)?;

    if state.current_owner != sender {
        return Err(ContractError::Unauthorized {});
    }
    Ok(())
}
