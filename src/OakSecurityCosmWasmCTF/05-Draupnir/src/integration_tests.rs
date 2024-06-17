#[cfg(test)]
pub mod tests {
    use crate::contract::DENOM;
    use crate::msg::{ExecuteMsg, InstantiateMsg, QueryMsg};
    use crate::state::State;
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

    pub const USER1: &str = "user1";
    pub const USER2: &str = "user2";
    pub const ADMIN: &str = "admin";

    pub fn base_scenario() -> (App, Addr) {
        let mut app = App::default();
        let cw_template_id = app.store_code(challenge_contract());

        // init contract
        let msg = InstantiateMsg {
            owner: ADMIN.to_string(),
        };
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

        // User 1 deposit
        app = mint_tokens(app, USER1.to_owned(), Uint128::new(10_000));
        app.execute_contract(
            Addr::unchecked(USER1),
            contract_addr.clone(),
            &ExecuteMsg::Deposit {},
            &[coin(10_000, DENOM)],
        )
        .unwrap();

        // User 2 deposit
        app = mint_tokens(app, USER2.to_owned(), Uint128::new(10_000));
        app.execute_contract(
            Addr::unchecked(USER2),
            contract_addr.clone(),
            &ExecuteMsg::Deposit {},
            &[coin(10_000, DENOM)],
        )
        .unwrap();

        (app, contract_addr)
    }

    pub fn proper_instantiate() -> (App, Addr) {
        let mut app = App::default();
        let cw_template_id = app.store_code(challenge_contract());

        // init contract
        let msg = InstantiateMsg {
            owner: ADMIN.to_string(),
        };
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

        // mint funds to user
        app = mint_tokens(app, USER1.to_owned(), Uint128::new(10_000));
        app = mint_tokens(app, USER2.to_owned(), Uint128::new(8_000));

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

        // User 1 deposit
        app.execute_contract(
            Addr::unchecked(USER1),
            contract_addr.clone(),
            &ExecuteMsg::Deposit {},
            &[coin(10_000, DENOM)],
        )
        .unwrap();

        // User 2 deposit
        app.execute_contract(
            Addr::unchecked(USER2),
            contract_addr.clone(),
            &ExecuteMsg::Deposit {},
            &[coin(8_000, DENOM)],
        )
        .unwrap();

        // Query balances
        let balance: Uint128 = app
            .wrap()
            .query_wasm_smart(
                contract_addr.clone(),
                &QueryMsg::UserBalance {
                    address: USER1.to_string(),
                },
            )
            .unwrap();
        assert_eq!(balance, Uint128::new(10_000));

        let balance: Uint128 = app
            .wrap()
            .query_wasm_smart(
                contract_addr.clone(),
                &QueryMsg::UserBalance {
                    address: USER2.to_string(),
                },
            )
            .unwrap();
        assert_eq!(balance, Uint128::new(8_000));

        let bal = app
            .wrap()
            .query_balance(contract_addr.to_string(), DENOM)
            .unwrap();
        assert_eq!(bal.amount, Uint128::new(18_000));

        // Withdraw user 1
        app.execute_contract(
            Addr::unchecked(USER1),
            contract_addr.clone(),
            &ExecuteMsg::Withdraw {
                amount: Uint128::new(5_000),
            },
            &[],
        )
        .unwrap();

        // Query balances
        let balance: Uint128 = app
            .wrap()
            .query_wasm_smart(
                contract_addr.clone(),
                &QueryMsg::UserBalance {
                    address: USER1.to_string(),
                },
            )
            .unwrap();
        assert_eq!(balance, Uint128::new(5_000));

        let bal = app
            .wrap()
            .query_balance(contract_addr.to_string(), DENOM)
            .unwrap();
        assert_eq!(bal.amount, Uint128::new(13_000));
    }

    #[test]
    fn ownership_flow() {
        let (mut app, contract_addr) = proper_instantiate();

        // Initial state
        let state: State = app
            .wrap()
            .query_wasm_smart(contract_addr.clone(), &QueryMsg::State {})
            .unwrap();

        assert_eq!(
            state,
            State {
                current_owner: Addr::unchecked(ADMIN),
                proposed_owner: None,
            }
        );

        // Ownership transfer
        app.execute_contract(
            Addr::unchecked(ADMIN),
            contract_addr.clone(),
            &ExecuteMsg::ProposeNewOwner {
                new_owner: "new_owner".to_string(),
            },
            &[],
        )
        .unwrap();

        app.execute_contract(
            Addr::unchecked("new_owner"),
            contract_addr.clone(),
            &ExecuteMsg::AcceptOwnership {},
            &[],
        )
        .unwrap();

        // Final state
        let state: State = app
            .wrap()
            .query_wasm_smart(contract_addr, &QueryMsg::State {})
            .unwrap();

        assert_eq!(
            state,
            State {
                current_owner: Addr::unchecked("new_owner"),
                proposed_owner: None,
            }
        );
    }
}
