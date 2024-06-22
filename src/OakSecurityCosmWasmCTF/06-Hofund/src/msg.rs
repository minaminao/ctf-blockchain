use cosmwasm_schema::cw_serde;
use cosmwasm_std::CosmosMsg;
use cw20::Cw20ReceiveMsg;

#[cw_serde]
pub struct InstantiateMsg {
    pub token: String,
    pub owner: String,
    pub window: u64,
}

#[cw_serde]
pub enum ExecuteMsg {
    Propose {},
    ResolveProposal {},
    OwnerAction { action: CosmosMsg },
    Receive(Cw20ReceiveMsg),
}

#[cw_serde]
pub enum Cw20HookMsg {
    CastVote {},
}

#[cw_serde]
pub enum QueryMsg {
    Config {},
    Proposal {},
    Balance {},
}
