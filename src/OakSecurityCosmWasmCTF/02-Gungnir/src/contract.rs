#[cfg(not(feature = "library"))]
use cosmwasm_std::entry_point;
use cosmwasm_std::{
    coin, to_binary, BankMsg, Binary, Deps, DepsMut, Env, MessageInfo, Response, StdResult, Uint128,
};
use cw_utils::must_pay;

use crate::error::ContractError;
use crate::msg::{ExecuteMsg, InstantiateMsg, QueryMsg};
use crate::state::{UserInfo, VOTING_POWER};

pub const DENOM: &str = "uawesome";
pub const LOCK_PERIOD: u64 = 60 * 60 * 24; // One day

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
        ExecuteMsg::Deposit {} => deposit(deps, info),
        ExecuteMsg::Withdraw { amount } => withdraw(deps, info, amount),
        ExecuteMsg::Stake { lock_amount } => stake(deps, env, info, lock_amount),
        ExecuteMsg::Unstake { unlock_amount } => unstake(deps, env, info, unlock_amount),
    }
}

/// Entry point for user to stake tokens
pub fn deposit(deps: DepsMut, info: MessageInfo) -> Result<Response, ContractError> {
    // validate denom
    let amount = must_pay(&info, DENOM).unwrap();

    // increase total stake
    let mut user = VOTING_POWER
        .load(deps.storage, &info.sender)
        .unwrap_or_default();
    user.total_tokens += amount;

    VOTING_POWER
        .save(deps.storage, &info.sender, &user)
        .unwrap();

    Ok(Response::new()
        .add_attribute("action", "deposit")
        .add_attribute("user", info.sender)
        .add_attribute("amount", amount))
}

/// Entry point for users to withdraw staked tokens
pub fn withdraw(
    deps: DepsMut,
    info: MessageInfo,
    amount: Uint128,
) -> Result<Response, ContractError> {
    // decrease total stake
    let mut user = VOTING_POWER.load(deps.storage, &info.sender).unwrap();

    user.total_tokens -= amount;

    // cannot withdraw staked tokens
    if user.total_tokens.u128() < user.voting_power {
        return Err(ContractError::Unauthorized {});
    }

    VOTING_POWER
        .save(deps.storage, &info.sender, &user)
        .unwrap();

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

/// Entry point for user to stake tokens for voting power
pub fn stake(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    lock_amount: u128,
) -> Result<Response, ContractError> {
    // increase voting power
    let mut user = VOTING_POWER.load(deps.storage, &info.sender).unwrap();

    user.voting_power += lock_amount;

    // cannot stake more than total tokens
    if user.voting_power > user.total_tokens.u128() {
        return Err(ContractError::Unauthorized {});
    }

    user.released_time = env.block.time.plus_seconds(LOCK_PERIOD);

    VOTING_POWER
        .save(deps.storage, &info.sender, &user)
        .unwrap();

    Ok(Response::new()
        .add_attribute("action", "stake")
        .add_attribute("lock_amount", lock_amount.to_string())
        .add_attribute("user.voting_power", user.voting_power.to_string()))
}

/// Entry point for users to decrease voting power
pub fn unstake(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    unlock_amount: u128,
) -> Result<Response, ContractError> {
    // decrease voting power
    let mut user = VOTING_POWER.load(deps.storage, &info.sender).unwrap();

    // check release time
    if env.block.time < user.released_time {
        return Err(ContractError::Unauthorized {});
    }

    user.voting_power -= unlock_amount;

    VOTING_POWER
        .save(deps.storage, &info.sender, &user)
        .unwrap();

    Ok(Response::new()
        .add_attribute("action", "unstake")
        .add_attribute("unlock_amount", unlock_amount.to_string())
        .add_attribute("user.voting_power", user.voting_power.to_string()))
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::GetUser { user } => to_binary(&get_user(deps, user)?),
        QueryMsg::GetVotingPower { user } => to_binary(&get_voting_power(deps, user)?),
    }
}

/// Returns user information from a specified user address
pub fn get_user(deps: Deps, user: String) -> StdResult<UserInfo> {
    let user_addr = deps.api.addr_validate(&user).unwrap();
    Ok(VOTING_POWER.load(deps.storage, &user_addr).unwrap())
}

/// Returns voting power for a specified user address
pub fn get_voting_power(deps: Deps, user: String) -> StdResult<u128> {
    let user_addr = deps.api.addr_validate(&user).unwrap();
    Ok(VOTING_POWER
        .load(deps.storage, &user_addr)
        .unwrap()
        .voting_power)
}
