#[cfg(not(feature = "library"))]
use cosmwasm_std::{
    coin, entry_point, to_binary, BankMsg, Binary, CosmosMsg, Deps, DepsMut, Env, MessageInfo,
    Response, StdResult, Uint128,
};

use crate::error::ContractError;
use crate::msg::{ExecuteMsg, InstantiateMsg, QueryMsg};
use crate::state::{assert_owner, State, BALANCES, STATE};
use cw_utils::must_pay;

pub const DENOM: &str = "uawesome";

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn instantiate(
    deps: DepsMut,
    _env: Env,
    _info: MessageInfo,
    msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    let state = State {
        current_owner: deps.api.addr_validate(&msg.owner)?,
        proposed_owner: None,
    };
    STATE.save(deps.storage, &state)?;

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
        ExecuteMsg::ProposeNewOwner { new_owner } => propose_owner(deps, info, new_owner),
        ExecuteMsg::AcceptOwnership {} => accept_owner(deps, info),
        ExecuteMsg::DropOwnershipProposal {} => drop_owner(deps, info),
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

/// Entry point for owner to execute arbitrary Cosmos messages
pub fn owner_action(
    deps: DepsMut,
    info: MessageInfo,
    msg: CosmosMsg,
) -> Result<Response, ContractError> {
    assert_owner(deps.storage, info.sender)?;

    Ok(Response::new()
        .add_attribute("action", "owner_action")
        .add_message(msg))
}

/// Entry point for current owner to propose a new owner
pub fn propose_owner(
    deps: DepsMut,
    info: MessageInfo,
    new_owner: String,
) -> Result<Response, ContractError> {
    assert_owner(deps.storage, info.sender)?;

    STATE.update(deps.storage, |mut state| -> StdResult<_> {
        state.proposed_owner = Some(deps.api.addr_validate(&new_owner)?);
        Ok(state)
    })?;

    Ok(Response::new()
        .add_attribute("action", "propose_owner")
        .add_attribute("new proposal", new_owner))
}

/// Entry point for new owner to accept a pending ownership transfer
pub fn accept_owner(deps: DepsMut, info: MessageInfo) -> Result<Response, ContractError> {
    let state = STATE.load(deps.storage)?;

    if state.proposed_owner != Some(info.sender.clone()) {
        ContractError::Unauthorized {};
    }

    STATE.update(deps.storage, |mut state| -> StdResult<_> {
        state.current_owner = info.sender.clone();
        state.proposed_owner = None;
        Ok(state)
    })?;

    Ok(Response::new()
        .add_attribute("action", "accept_owner")
        .add_attribute("new owner", info.sender))
}

/// Entry point for current owner to drop pending ownership
pub fn drop_owner(deps: DepsMut, info: MessageInfo) -> Result<Response, ContractError> {
    assert_owner(deps.storage, info.sender)?;

    STATE.update(deps.storage, |mut state| -> StdResult<_> {
        state.proposed_owner = None;
        Ok(state)
    })?;

    Ok(Response::new().add_attribute("action", "drop_owner"))
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::State {} => to_binary(&query_state(deps)?),
        QueryMsg::UserBalance { address } => to_binary(&query_balance(deps, address)?),
    }
}

/// Returns user balance
pub fn query_balance(deps: Deps, address: String) -> StdResult<Uint128> {
    let address = deps.api.addr_validate(&address)?;
    BALANCES.load(deps.storage, &address)
}

/// Returns contract state
pub fn query_state(deps: Deps) -> StdResult<State> {
    STATE.load(deps.storage)
}
