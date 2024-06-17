#[cfg(test)]
pub mod tests {
    use crate::contract::DENOM;
    use common::flash_loan::{Config, ExecuteMsg, FlashLoanState, InstantiateMsg, QueryMsg};
    use cosmwasm_std::{coin, Addr, Empty, Uint128};
    use cw_multi_test::{App, Contract, ContractWrapper, Executor};

    pub fn challenge_contract() -> Box<dyn Contract<Empty>> {
        let contract = ContractWrapper::new(
            crate::contract::execute,
            crate::contract::instantiate,
            crate::contract::query,
        );
        Box::new(contract)
    }

    pub const USER: &str = "user";
    pub const ADMIN: &str = "admin";

    pub fn proper_instantiate() -> (App, Addr) {
        let mut app = App::default();
        let cw_template_id = app.store_code(challenge_contract());

        // init contract
        let msg = InstantiateMsg {};
        let contract_addr = app
            .instantiate_contract(
                cw_template_id,
                Addr::unchecked(ADMIN),
                &msg,
                &[],
                "test",
                None,
            )
            .unwrap();

        // mint funds to contract
        app = mint_tokens(app, contract_addr.to_string(), Uint128::new(10_000));

        (app, contract_addr)
    }

    pub fn mint_tokens(mut app: App, recipient: String, amount: Uint128) -> App {
        app.sudo(cw_multi_test::SudoMsg::Bank(
            cw_multi_test::BankSudo::Mint {
                to_address: recipient,
                amount: vec![coin(amount.u128(), DENOM)],
            },
        ))
        .unwrap();
        app
    }

    #[test]
    fn basic_flow() {
        let (mut app, contract_addr) = proper_instantiate();

        // check query
        let config: Config = app
            .wrap()
            .query_wasm_smart(contract_addr.clone(), &QueryMsg::Config {})
            .unwrap();
        assert_eq!(config.owner.to_string(), ADMIN);
        assert_eq!(config.proxy_addr, None);

        let state: FlashLoanState = app
            .wrap()
            .query_wasm_smart(contract_addr.clone(), &QueryMsg::FlashLoanState {})
            .unwrap();
        assert_eq!(state.requested_amount, None);

        // try set proxy addr
        app.execute_contract(
            Addr::unchecked(USER),
            contract_addr.clone(),
            &ExecuteMsg::SetProxyAddr {
                proxy_addr: USER.to_owned(),
            },
            &[],
        )
        .unwrap_err();

        app.execute_contract(
            Addr::unchecked(ADMIN),
            contract_addr.clone(),
            &ExecuteMsg::SetProxyAddr {
                proxy_addr: ADMIN.to_owned(),
            },
            &[],
        )
        .unwrap();

        // execute a flash loan
        app.execute_contract(
            Addr::unchecked(ADMIN),
            contract_addr.clone(),
            &ExecuteMsg::FlashLoan {},
            &[],
        )
        .unwrap();

        // cannot execute twice
        app.execute_contract(
            Addr::unchecked(ADMIN),
            contract_addr.clone(),
            &ExecuteMsg::FlashLoan {},
            &[],
        )
        .unwrap_err();

        // ensure funds received
        let balance = app.wrap().query_balance(ADMIN, DENOM).unwrap();
        assert_eq!(balance.amount, Uint128::new(10_000));

        // only proxy address can settle loan
        app.execute_contract(
            Addr::unchecked(USER),
            contract_addr.clone(),
            &ExecuteMsg::SettleLoan {},
            &[],
        )
        .unwrap_err();

        // cannot settle when amount not returned
        app.execute_contract(
            Addr::unchecked(ADMIN),
            contract_addr.clone(),
            &ExecuteMsg::SettleLoan {},
            &[],
        )
        .unwrap_err();

        // can only settle after fully paid
        app.send_tokens(
            Addr::unchecked(ADMIN),
            contract_addr.clone(),
            &[coin(9999_u128, DENOM)],
        )
        .unwrap();

        app.execute_contract(
            Addr::unchecked(ADMIN),
            contract_addr.clone(),
            &ExecuteMsg::SettleLoan {},
            &[],
        )
        .unwrap_err();

        // send the rest and pay off loan
        app.send_tokens(
            Addr::unchecked(ADMIN),
            contract_addr.clone(),
            &[coin(1_u128, DENOM)],
        )
        .unwrap();

        app.execute_contract(
            Addr::unchecked(ADMIN),
            contract_addr.clone(),
            &ExecuteMsg::SettleLoan {},
            &[],
        )
        .unwrap();

        // cannot settle twice
        app.execute_contract(
            Addr::unchecked(ADMIN),
            contract_addr.clone(),
            &ExecuteMsg::SettleLoan {},
            &[],
        )
        .unwrap_err();

        // contract have funds
        let balance = app
            .wrap()
            .query_balance(contract_addr.to_string(), DENOM)
            .unwrap();
        assert_eq!(balance.amount, Uint128::new(10_000));

        // withdraw funds
        app.execute_contract(
            Addr::unchecked(ADMIN),
            contract_addr.clone(),
            &ExecuteMsg::WithdrawFunds {
                recipient: Addr::unchecked(ADMIN),
            },
            &[],
        )
        .unwrap();

        let balance = app.wrap().query_balance(ADMIN, DENOM).unwrap();
        assert_eq!(balance.amount, Uint128::new(10_000));

        let balance = app
            .wrap()
            .query_balance(contract_addr.to_string(), DENOM)
            .unwrap();
        assert_eq!(balance.amount, Uint128::zero());

        // change admin works
        app.execute_contract(
            Addr::unchecked(ADMIN),
            contract_addr,
            &ExecuteMsg::TransferOwner {
                new_owner: Addr::unchecked(USER),
            },
            &[],
        )
        .unwrap();
    }
}
