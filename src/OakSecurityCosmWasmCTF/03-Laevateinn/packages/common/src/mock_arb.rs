use cosmwasm_schema::{cw_serde, QueryResponses};
use cosmwasm_std::Addr;

#[cw_serde]
pub struct InstantiateMsg {}

#[cw_serde]
pub enum ExecuteMsg {
    Arbitrage { recipient: Addr },
}

#[cw_serde]
#[derive(QueryResponses)]
pub enum QueryMsg {}

#[cw_serde]
pub struct Config {}
