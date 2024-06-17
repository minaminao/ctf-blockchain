#[cfg(not(feature = "library"))]
use cosmwasm_std::entry_point;
use cosmwasm_std::{Addr, BankMsg, Binary, Deps, DepsMut, Env, MessageInfo, Response, StdResult};
use cw_utils::must_pay;

use crate::error::ContractError;

use common::mock_arb::{ExecuteMsg, InstantiateMsg, QueryMsg};

pub const DENOM: &str = "uawesome";

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn instantiate(
    _deps: DepsMut,
    _env: Env,
    _info: MessageInfo,
    _msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    Ok(Response::new().add_attribute("action", "instantiate"))
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn execute(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        ExecuteMsg::Arbitrage { recipient } => arbitrage(deps, env, info, recipient),
    }
}

pub fn arbitrage(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    recipient: Addr,
) -> Result<Response, ContractError> {
    let received_amount = must_pay(&info, DENOM).unwrap();

    // Some arbitrage stuffs..

    let contract_balance = deps
        .querier
        .query_balance(env.contract.address.to_string(), DENOM)
        .unwrap();

    // This contract does not intend to hold any funds
    let msg = BankMsg::Send {
        to_address: recipient.to_string(),
        amount: vec![contract_balance.clone()],
    };

    Ok(Response::new()
        .add_attribute("action", "arbitrage")
        .add_attribute("sent_amount", received_amount)
        .add_attribute("contract_balance", contract_balance.amount)
        .add_message(msg))
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn query(_deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {}
}
