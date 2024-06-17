use cosmwasm_schema::{cw_serde, QueryResponses};
use cosmwasm_std::{Addr, Binary};

#[cw_serde]
pub struct InstantiateMsg {
    pub flash_loan_addr: String,
}

#[cw_serde]
pub enum ExecuteMsg {
    RequestFlashLoan { recipient: Addr, msg: Binary },
}

#[cw_serde]
#[derive(QueryResponses)]
pub enum QueryMsg {
    #[returns(Addr)]
    GetFlashLoanAddress {},
}

#[cw_serde]
pub struct Config {
    /// Flash loan address
    pub flash_loan_addr: Addr,
}
