use cosmwasm_std::StdError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ContractError {
    #[error("{0}")]
    Std(#[from] StdError),

    #[error("Unauthorized")]
    Unauthorized {},

    #[error("The voting window is closed")]
    VotingWindowClosed {},

    #[error("A proposal already exists")]
    ProposalAlreadyExists {},

    #[error("No proposal exists")]
    ProposalDoesNotExists {},

    #[error("The proposal is not ready yet")]
    ProposalNotReady {},
}
