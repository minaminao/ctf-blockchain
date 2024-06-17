#[cfg(not(feature = "library"))]
use cosmwasm_std::entry_point;
use cosmwasm_std::{
    to_binary, Addr, Binary, CosmosMsg, Deps, DepsMut, Env, MessageInfo, Response, StdResult,
    WasmMsg,
};

use crate::error::ContractError;
use crate::state::CONFIG;
use common::flash_loan::{
    Config as FlashLoanConfig, ExecuteMsg as FlashLoanExecuteMsg, QueryMsg as FlashLoanQueryMsg,
};
use common::proxy::{Config, ExecuteMsg, InstantiateMsg, QueryMsg};

pub const DENOM: &str = "uawesome";

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    _info: MessageInfo,
    msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    let flash_loan_addr = deps.api.addr_validate(&msg.flash_loan_addr).unwrap();

    let state = Config { flash_loan_addr };
    CONFIG.save(deps.storage, &state)?;

    Ok(Response::new()
        .add_attribute("action", "instantiate")
        .add_attribute("flash_loan_addr", msg.flash_loan_addr))
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn execute(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        ExecuteMsg::RequestFlashLoan { recipient, msg } => {
            request_flash_loan(deps, env, info, recipient, msg)
        }
    }
}

/// Entry point for user to request flash loan
pub fn request_flash_loan(
    deps: DepsMut,
    env: Env,
    _info: MessageInfo,
    recipient: Addr,
    msg: Binary,
) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;

    // Disallow calling flash loan addr
    if recipient == config.flash_loan_addr {
        return Err(ContractError::CallToFlashLoan {});
    }

    let flash_loan_config: FlashLoanConfig = deps.querier.query_wasm_smart(
        config.flash_loan_addr.to_string(),
        &FlashLoanQueryMsg::Config {},
    )?;

    // Ensure we have calling permissions
    if flash_loan_config.proxy_addr.is_none()
        || flash_loan_config.proxy_addr.unwrap() != env.contract.address
    {
        return Err(ContractError::ContractNoSetProxyAddr {});
    }

    let mut msgs: Vec<CosmosMsg> = vec![];

    // 1. Request flash loan
    msgs.push(CosmosMsg::Wasm(WasmMsg::Execute {
        contract_addr: config.flash_loan_addr.to_string(),
        msg: to_binary(&FlashLoanExecuteMsg::FlashLoan {})?,
        funds: vec![],
    }));

    // 2. Callback
    let flash_loan_balance = deps
        .querier
        .query_balance(config.flash_loan_addr.to_string(), DENOM)
        .unwrap();

    msgs.push(CosmosMsg::Wasm(WasmMsg::Execute {
        contract_addr: recipient.to_string(),
        msg,
        funds: vec![flash_loan_balance],
    }));

    // 3. Settle loan
    msgs.push(CosmosMsg::Wasm(WasmMsg::Execute {
        contract_addr: config.flash_loan_addr.to_string(),
        msg: to_binary(&FlashLoanExecuteMsg::SettleLoan {})?,
        funds: vec![],
    }));

    Ok(Response::new()
        .add_attribute("action", "request_flash_loan")
        .add_messages(msgs))
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::GetFlashLoanAddress {} => to_binary(&get_flash_loan_addr(deps)?),
    }
}

/// Returns flash loan contract address
pub fn get_flash_loan_addr(deps: Deps) -> StdResult<Addr> {
    let config = CONFIG.load(deps.storage)?;
    Ok(config.flash_loan_addr)
}
