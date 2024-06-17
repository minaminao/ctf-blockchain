use cosmwasm_schema::{cw_serde, QueryResponses};
use cosmwasm_std::{Addr, Uint128};

#[cw_serde]
pub struct InstantiateMsg {}

#[cw_serde]
pub enum ExecuteMsg {
    SetProxyAddr { proxy_addr: String },
    FlashLoan {},
    SettleLoan {},
    WithdrawFunds { recipient: Addr },
    TransferOwner { new_owner: Addr },
}

#[cw_serde]
#[derive(QueryResponses)]
pub enum QueryMsg {
    #[returns(Config)]
    Config {},

    #[returns(FlashLoanState)]
    FlashLoanState {},
}

#[cw_serde]
pub struct GetCountResponse {
    pub count: i32,
}

#[cw_serde]
pub struct Config {
    pub owner: Addr,
    pub proxy_addr: Option<Addr>,
}

#[cw_serde]
pub struct FlashLoanState {
    pub requested_amount: Option<Uint128>,
}
