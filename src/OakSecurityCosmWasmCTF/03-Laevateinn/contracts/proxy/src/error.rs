use cosmwasm_std::StdError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),

    #[error("Unauthorized")]
    Unauthorized {},

    #[error("Calling to flash loan contract is disallowed")]
    CallToFlashLoan {},

    #[error("Flash loan contract did not set proxy address properly")]
    ContractNoSetProxyAddr {},
}
