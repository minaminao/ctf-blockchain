use cosmwasm_std::StdError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),

    #[error("Unauthorized")]
    Unauthorized {},

    #[error("Proxy address is not set")]
    ProxyAddressNotSet {},

    #[error("Proxy address is already set")]
    ProxyAddressAlreadySet {},

    #[error("Contract have zero balance")]
    ZeroBalance {},

    #[error("Flash loan is already executed")]
    OngoingFlashLoan {},

    #[error("No flash loan is executed")]
    NoFlashLoan {},

    #[error("Requested amount is too large")]
    RequestedTooHighAmount {},
}
