#[cfg(not(feature = "library"))]
use cosmwasm_std::entry_point;
use cosmwasm_std::{
    to_binary, BankMsg, Binary, Coin, Deps, DepsMut, Env, MessageInfo, Response, StdResult, Uint128,
};

use crate::error::ContractError;
use crate::msg::{ExecuteMsg, InstantiateMsg, QueryMsg};
use crate::state::{Lockup, LAST_ID, LOCKUPS};
use cw_utils::must_pay;

pub const DENOM: &str = "uawesome";
pub const MINIMUM_DEPOSIT_AMOUNT: Uint128 = Uint128::new(10_000);
pub const LOCK_PERIOD: u64 = 60 * 60 * 24;

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
        ExecuteMsg::Deposit {} => deposit(deps, env, info),
        ExecuteMsg::Withdraw { ids } => withdraw(deps, env, info, ids),
    }
}

/// Deposit entry point for users
pub fn deposit(deps: DepsMut, env: Env, info: MessageInfo) -> Result<Response, ContractError> {
    // check minimum amount and denom
    let amount = must_pay(&info, DENOM).unwrap();

    if amount < MINIMUM_DEPOSIT_AMOUNT {
        return Err(ContractError::Unauthorized {});
    }

    // increment lock id
    let id = LAST_ID.load(deps.storage).unwrap_or(1);
    LAST_ID.save(deps.storage, &(id + 1)).unwrap();

    // create lockup
    let lock = Lockup {
        id,
        owner: info.sender,
        amount,
        release_timestamp: env.block.time.plus_seconds(LOCK_PERIOD),
    };

    // save lockup
    LOCKUPS.save(deps.storage, id, &lock).unwrap();

    Ok(Response::new()
        .add_attribute("action", "deposit")
        .add_attribute("id", lock.id.to_string())
        .add_attribute("owner", lock.owner)
        .add_attribute("amount", lock.amount)
        .add_attribute("release_timestamp", lock.release_timestamp.to_string()))
}

/// Withdrawal entry point for users
pub fn withdraw(
    deps: DepsMut,
    env: Env,
    info: MessageInfo,
    ids: Vec<u64>,
) -> Result<Response, ContractError> {
    let mut lockups: Vec<Lockup> = vec![];
    let mut total_amount = Uint128::zero();

    // fetch vaults to process
    for lockup_id in ids.clone() {
        let lockup = LOCKUPS.load(deps.storage, lockup_id).unwrap();
        lockups.push(lockup);
    }

    for lockup in lockups {
        // validate owner and time
        if lockup.owner != info.sender || env.block.time < lockup.release_timestamp {
            return Err(ContractError::Unauthorized {});
        }

        // increase total amount
        total_amount += lockup.amount;

        // remove from storage
        LOCKUPS.remove(deps.storage, lockup.id);
    }

    let msg = BankMsg::Send {
        to_address: info.sender.to_string(),
        amount: vec![Coin {
            denom: DENOM.to_string(),
            amount: total_amount,
        }],
    };

    Ok(Response::new()
        .add_attribute("action", "withdraw")
        .add_attribute("ids", format!("{:?}", ids))
        .add_attribute("total_amount", total_amount)
        .add_message(msg))
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::GetLockup { id } => to_binary(&get_lockup(deps, id)?),
    }
}

/// Returns lockup information for a specified id
pub fn get_lockup(deps: Deps, id: u64) -> StdResult<Lockup> {
    Ok(LOCKUPS.load(deps.storage, id).unwrap())
}
