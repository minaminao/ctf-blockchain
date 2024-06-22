#[cfg(not(feature = "library"))]
use cosmwasm_std::{
    coin, entry_point, to_binary, Addr, BankMsg, Binary, CosmosMsg, Deps, DepsMut, Env,
    MessageInfo, Response, StdResult, Uint128,
};
use cw_storage_plus::Item;

use crate::error::ContractError;
use crate::msg::{ConfigQueryResponse, ExecuteMsg, InstantiateMsg, QueryMsg};
use crate::state::{BALANCES, OWNER, THRESHOLD};
use cw_utils::must_pay;

pub const DENOM: &str = "uawesome";
pub const TOP_DEPOSITOR: Item<Addr> = Item::new("address");

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    _info: MessageInfo,
    msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    OWNER.save(deps.storage, &deps.api.addr_validate(&msg.owner)?)?;

    THRESHOLD.save(deps.storage, &msg.threshold)?;

    Ok(Response::new()
        .add_attribute("action", "instantiate")
        .add_attribute("owner", msg.owner))
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn execute(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    match msg {
        ExecuteMsg::Deposit {} => deposit(deps, info),
        ExecuteMsg::Withdraw { amount } => withdraw(deps, info, amount),
        ExecuteMsg::OwnerAction { msg } => owner_action(deps, info, msg),
        ExecuteMsg::UpdateConfig { new_threshold } => update_config(deps, info, new_threshold),
    }
}

/// Deposit entry point for user
pub fn deposit(deps: DepsMut, info: MessageInfo) -> Result<Response, ContractError> {
    // validate denom
    let amount = must_pay(&info, DENOM).unwrap();

    // increase total stake
    let mut user_balance = BALANCES
        .load(deps.storage, &info.sender)
        .unwrap_or_default();
    user_balance += amount;

    BALANCES.save(deps.storage, &info.sender, &user_balance)?;

    let current_threshold = THRESHOLD.load(deps.storage)?;

    if user_balance > current_threshold {
        THRESHOLD.save(deps.storage, &user_balance)?;
        TOP_DEPOSITOR.save(deps.storage, &info.sender)?;
    }

    Ok(Response::new()
        .add_attribute("action", "deposit")
        .add_attribute("user", info.sender)
        .add_attribute("amount", amount))
}

/// Withdrawal entry point for user
pub fn withdraw(
    deps: DepsMut,
    info: MessageInfo,
    amount: Uint128,
) -> Result<Response, ContractError> {
    // decrease total stake
    let mut user_balance = BALANCES.load(deps.storage, &info.sender)?;

    // Cosmwasm's Uint128 checks math operations
    user_balance -= amount;

    BALANCES.save(deps.storage, &info.sender, &user_balance)?;

    let msg = BankMsg::Send {
        to_address: info.sender.to_string(),
        amount: vec![coin(amount.u128(), DENOM)],
    };

    Ok(Response::new()
        .add_attribute("action", "withdraw")
        .add_attribute("user", info.sender)
        .add_attribute("amount", amount)
        .add_message(msg))
}

/// Entry point for owner to update threshold
pub fn update_config(
    deps: DepsMut,
    info: MessageInfo,
    new_threshold: Uint128,
) -> Result<Response, ContractError> {
    let owner = OWNER.load(deps.storage)?;

    if owner != info.sender {
        return Err(ContractError::Unauthorized {});
    }

    THRESHOLD.save(deps.storage, &new_threshold)?;

    Ok(Response::new()
        .add_attribute("action", "Update config")
        .add_attribute("threshold", new_threshold))
}

/// Entry point for owner to execute arbitrary Cosmos messages
pub fn owner_action(
    deps: DepsMut,
    info: MessageInfo,
    msg: CosmosMsg,
) -> Result<Response, ContractError> {
    let owner = OWNER.load(deps.storage)?;

    if owner != info.sender {
        return Err(ContractError::Unauthorized {});
    }

    Ok(Response::new()
        .add_attribute("action", "owner_action")
        .add_message(msg))
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::Config {} => to_binary(&query_config(deps)?),
        QueryMsg::UserBalance { address } => to_binary(&query_balance(deps, address)?),
        QueryMsg::Top {} => to_binary(&query_top_depositor(deps)?),
    }
}

/// Returns balance for specified address
pub fn query_balance(deps: Deps, address: String) -> StdResult<Uint128> {
    let address = deps.api.addr_validate(&address)?;
    BALANCES.load(deps.storage, &address)
}

/// Returns contract configuration
pub fn query_config(deps: Deps) -> StdResult<ConfigQueryResponse> {
    let owner = OWNER.load(deps.storage)?;
    let threshold = THRESHOLD.load(deps.storage)?;

    Ok(ConfigQueryResponse { owner, threshold })
}

/// Returns the top depositor
pub fn query_top_depositor(deps: Deps) -> StdResult<Addr> {
    TOP_DEPOSITOR.load(deps.storage)
}
