use cosmwasm_schema::{cw_serde, QueryResponses};

use crate::state::Lockup;

#[cw_serde]
pub struct InstantiateMsg {
    pub count: i32,
}

#[cw_serde]
pub enum ExecuteMsg {
    Deposit {},
    Withdraw { ids: Vec<u64> },
}

#[cw_serde]
#[derive(QueryResponses)]
pub enum QueryMsg {
    #[returns(Lockup)]
    GetLockup { id: u64 },
}
