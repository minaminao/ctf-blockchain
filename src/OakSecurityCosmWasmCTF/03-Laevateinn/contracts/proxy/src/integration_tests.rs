#[cfg(test)]
pub mod tests {
    use crate::contract::DENOM;
    use common::flash_loan::{
        ExecuteMsg as FlashLoanExecuteMsg, InstantiateMsg as FlashLoanInstantiateMsg,
    };
    use common::mock_arb::{
        ExecuteMsg as MockArbExecuteMsg, InstantiateMsg as MockArbInstantiateMsg,
    };
    use common::proxy::{ExecuteMsg, InstantiateMsg};
    use cosmwasm_std::{coin, to_binary, Addr, Empty, Uint128};
    use cw_multi_test::{App, Contract, ContractWrapper, Executor};

    pub fn proxy_contract() -> Box<dyn Contract<Empty>> {
        let contract = ContractWrapper::new(
            crate::contract::execute,
            crate::contract::instantiate,
            crate::contract::query,
        );
        Box::new(contract)
    }

    pub fn flash_loan_contract() -> Box<dyn Contract<Empty>> {
        let contract = ContractWrapper::new(
            flash_loan::contract::execute,
            flash_loan::contract::instantiate,
            flash_loan::contract::query,
        );
        Box::new(contract)
    }

    pub fn mock_arb_contract() -> Box<dyn Contract<Empty>> {
        let contract = ContractWrapper::new(
            mock_arb::contract::execute,
            mock_arb::contract::instantiate,
            mock_arb::contract::query,
        );
        Box::new(contract)
    }

    pub const USER: &str = "user";
    pub const ADMIN: &str = "admin";

    pub fn proper_instantiate() -> (App, Addr, Addr, Addr) {
        let mut app = App::default();

        let cw_template_id = app.store_code(proxy_contract());
        let flash_loan_id = app.store_code(flash_loan_contract());
        let mock_arb_id = app.store_code(mock_arb_contract());

        // init flash loan contract
        let msg = FlashLoanInstantiateMsg {};
        let flash_loan_contract = app
            .instantiate_contract(
                flash_loan_id,
                Addr::unchecked(ADMIN),
                &msg,
                &[],
                "flash_loan",
                None,
            )
            .unwrap();

        // init proxy contract
        let msg = InstantiateMsg {
            flash_loan_addr: flash_loan_contract.to_string(),
        };
        let proxy_contract = app
            .instantiate_contract(
                cw_template_id,
                Addr::unchecked(ADMIN),
                &msg,
                &[],
                "proxy",
                None,
            )
            .unwrap();

        // init mock arb contract
        let msg = MockArbInstantiateMsg {};
        let mock_arb_contract = app
            .instantiate_contract(
                mock_arb_id,
                Addr::unchecked(ADMIN),
                &msg,
                &[],
                "mock_arb",
                None,
            )
            .unwrap();

        // mint funds to flash loan contract
        app = mint_tokens(app, flash_loan_contract.to_string(), Uint128::new(10_000));

        // set proxy contract
        app.execute_contract(
            Addr::unchecked(ADMIN),
            flash_loan_contract.clone(),
            &FlashLoanExecuteMsg::SetProxyAddr {
                proxy_addr: proxy_contract.to_string(),
            },
            &[],
        )
        .unwrap();

        (app, proxy_contract, flash_loan_contract, mock_arb_contract)
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
        let (mut app, proxy_contract, flash_loan_contract, mock_arb_contract) =
            proper_instantiate();

        // prepare arb msg
        let arb_msg = to_binary(&MockArbExecuteMsg::Arbitrage {
            recipient: flash_loan_contract.clone(),
        })
        .unwrap();

        // cannot call flash loan address from proxy
        app.execute_contract(
            Addr::unchecked(ADMIN),
            proxy_contract.clone(),
            &ExecuteMsg::RequestFlashLoan {
                recipient: flash_loan_contract.clone(),
                msg: arb_msg.clone(),
            },
            &[],
        )
        .unwrap_err();

        // try perform flash loan
        app.execute_contract(
            Addr::unchecked(ADMIN),
            proxy_contract,
            &ExecuteMsg::RequestFlashLoan {
                recipient: mock_arb_contract,
                msg: arb_msg,
            },
            &[],
        )
        .unwrap();

        // funds are sent back to flash loan contract
        let balance = app
            .wrap()
            .query_balance(flash_loan_contract.to_string(), DENOM)
            .unwrap();
        assert_eq!(balance.amount, Uint128::new(10_000));
    }
}
