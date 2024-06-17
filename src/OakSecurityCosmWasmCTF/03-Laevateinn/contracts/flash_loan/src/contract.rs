#[cfg(not(feature = "library"))]
use cosmwasm_std::entry_point;
use cosmwasm_std::{
    coin, to_binary, Addr, BankMsg, Binary, Deps, DepsMut, Env, MessageInfo, Response, StdResult,
};

use crate::error::ContractError;
use crate::state::{CONFIG, FLASH_LOAN};
use common::flash_loan::{Config, ExecuteMsg, FlashLoanState, InstantiateMsg, QueryMsg};

pub const DENOM: &str = "uawesome";

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    _msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    let state = Config {
        proxy_addr: None,
        owner: info.sender.clone(),
    };
    CONFIG.save(deps.storage, &state)?;

    let state = FlashLoanState {
        requested_amount: None,
    };

    FLASH_LOAN.save(deps.storage, &state)?;

    Ok(Response::new()
        .add_attribute("action", "instantiate")
        .add_attribute("owner", info.sender))
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn execute(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        ExecuteMsg::FlashLoan {} => flash_loan(deps, env, info),
        ExecuteMsg::SettleLoan {} => settle_loan(deps, env, info),
        ExecuteMsg::SetProxyAddr { proxy_addr } => set_proxy_addr(deps, info, proxy_addr),
        ExecuteMsg::WithdrawFunds { recipient } => withdraw_funds(deps, env, info, recipient),
        ExecuteMsg::TransferOwner { new_owner } => transfer_owner(deps, info, new_owner),
    }
}

/// Entry point to start a flash loan by the proxy contract
pub fn flash_loan(deps: DepsMut, env: Env, info: MessageInfo) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;

    let mut state = FLASH_LOAN.load(deps.storage)?;

    if state.requested_amount.is_some() {
        return Err(ContractError::OngoingFlashLoan {});
    }

    if config.proxy_addr.is_none() {
        return Err(ContractError::ProxyAddressNotSet {});
    }

    if info.sender != config.proxy_addr.unwrap() {
        return Err(ContractError::Unauthorized {});
    }

    let balance = deps.querier.query_balance(env.contract.address, DENOM)?;

    if balance.amount.is_zero() {
        return Err(ContractError::ZeroBalance {});
    }

    let msg = BankMsg::Send {
        to_address: info.sender.to_string(),
        amount: vec![coin(balance.amount.u128(), DENOM)],
    };

    state.requested_amount = Some(balance.amount);

    FLASH_LOAN.save(deps.storage, &state)?;

    Ok(Response::new()
        .add_attribute("action", "flash_loan")
        .add_attribute("amount", state.requested_amount.unwrap().to_string())
        .add_message(msg))
}

/// Entry point to settle a flash loan from the proxy contract
pub fn settle_loan(deps: DepsMut, env: Env, info: MessageInfo) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;

    let mut state = FLASH_LOAN.load(deps.storage)?;

    if state.requested_amount.is_none() {
        return Err(ContractError::NoFlashLoan {});
    }

    if config.proxy_addr.is_none() {
        return Err(ContractError::ProxyAddressNotSet {});
    }

    if info.sender != config.proxy_addr.unwrap() {
        return Err(ContractError::Unauthorized {});
    }

    let balance = deps.querier.query_balance(env.contract.address, DENOM)?;

    if balance.amount < state.requested_amount.unwrap() {
        return Err(ContractError::RequestedTooHighAmount {});
    }

    state.requested_amount = None;

    FLASH_LOAN.save(deps.storage, &state)?;

    Ok(Response::new().add_attribute("action", "settle_loan"))
}

/// Entry point for owner to set proxy address
pub fn set_proxy_addr(
    deps: DepsMut,
    info: MessageInfo,
    proxy_addr: String,
) -> Result<Response, ContractError> {
    let mut config = CONFIG.load(deps.storage)?;

    if info.sender != config.owner {
        return Err(ContractError::Unauthorized {});
    }

    if config.proxy_addr.is_none() {
        config.proxy_addr = Some(deps.api.addr_validate(&proxy_addr).unwrap());
    } else {
        return Err(ContractError::ProxyAddressAlreadySet {});
    }

    CONFIG.save(deps.storage, &config)?;

    Ok(Response::new().add_attribute("action", "set_proxy_addr"))
}

/// Entry point for owner to withdraw funds
pub fn withdraw_funds(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    recipient: Addr,
) -> Result<Response, ContractError> {
    let config = CONFIG.load(deps.storage)?;

    if info.sender != config.owner {
        return Err(ContractError::Unauthorized {});
    }

    let balance = deps.querier.query_balance(env.contract.address, DENOM)?;

    if balance.amount.is_zero() {
        return Err(ContractError::ZeroBalance {});
    }

    let msg = BankMsg::Send {
        to_address: recipient.to_string(),
        amount: vec![coin(balance.amount.u128(), DENOM)],
    };

    Ok(Response::new()
        .add_attribute("action", "withdraw_funds")
        .add_attribute("amount", balance.amount)
        .add_message(msg))
}

/// Entry point to transfer ownership
pub fn transfer_owner(
    deps: DepsMut,
    info: MessageInfo,
    new_owner: Addr,
) -> Result<Response, ContractError> {
    let mut config = CONFIG.load(deps.storage)?;

    if !is_trusted(&info.sender, &config) {
        return Err(ContractError::Unauthorized {});
    }

    config.owner = new_owner;

    CONFIG.save(deps.storage, &config)?;

    Ok(Response::new().add_attribute("action", "transfer_owner"))
}

pub fn is_trusted(sender: &Addr, config: &Config) -> bool {
    let mut trusted = false;

    if sender == config.owner {
        trusted = true;
    }

    if config.proxy_addr.is_some() && sender == config.proxy_addr.as_ref().unwrap() {
        trusted = true;
    }

    trusted
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::Config {} => to_binary(&query_config(deps)?),
        QueryMsg::FlashLoanState {} => to_binary(&query_flash_loan_state(deps)?),
    }
}

/// Returns contract configuration
pub fn query_config(deps: Deps) -> StdResult<Config> {
    let config = CONFIG.load(deps.storage)?;
    Ok(config)
}

/// Returns current flash loan state
pub fn query_flash_loan_state(deps: Deps) -> StdResult<FlashLoanState> {
    let state = FLASH_LOAN.load(deps.storage)?;
    Ok(state)
}
