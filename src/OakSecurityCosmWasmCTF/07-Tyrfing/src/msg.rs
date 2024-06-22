use cosmwasm_schema::cw_serde;
use cosmwasm_std::{Addr, CosmosMsg, Uint128};

#[cw_serde]
pub struct InstantiateMsg {
    pub owner: String,
    pub threshold: Uint128,
}

#[cw_serde]
pub enum ExecuteMsg {
    Deposit {},
    Withdraw { amount: Uint128 },
    OwnerAction { msg: CosmosMsg },
    UpdateConfig { new_threshold: Uint128 },
}

#[cw_serde]
pub enum QueryMsg {
    Config {},
    UserBalance { address: String },
    Top {},
}

// We define a custom struct for each query response
#[cw_serde]
pub struct ConfigQueryResponse {
    pub owner: Addr,
    pub threshold: Uint128,
}
