Fungible Token Contract in Rust
===============================

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/near-examples/rust-fungible-token)

<!-- MAGIC COMMENT: DO NOT DELETE! Everything above this line is hidden on NEAR Examples page -->

Example implementation of a Fungible Token Standard ([NEP#21](https://github.com/nearprotocol/neps/pull/21)).

Windows users: please visit the [Windows-specific README file](README-Windows.md).


Prerequisites
=============

1. Make sure Rust is installed per the prerequisites in [`near-sdk-rs`](https://github.com/nearprotocol/near-sdk-rs)
2. Make sure you have node.js installed (we like [asdf](https://github.com/asdf-vm/asdf) for this)
3. Ensure `near-shell` is installed by running `near --version`. If not installed, install with: `npm install --global near-shell`


Building this contract
======================

One command:

    npm run build

If you look in the `package.json` file at the `scripts` section, you'll see that that this runs `cargo build` with some special flags (Cargo is [the Rust package manager](https://doc.rust-lang.org/cargo/index.html)). `npm run build` also runs the `postbuild` script to copy the output to `./res`


Using this contract
===================

This smart contract will get deployed to your NEAR account. For this example, please create a new NEAR account. Because NEAR allows the ability to upgrade contracts on the same account, initialization functions must be cleared. If you'd like to run this example on a NEAR account that has had prior contracts, deployed please use `near-shell`'s command `near delete`, and then recreate it in Wallet. To create (or recreate) an account for this example, please follow the directions on [NEAR Wallet](https://wallet.nearprotocol.com).

In the project root, login with `near-shell` by following the instructions after this command:

    near login

To make this tutorial easier to copy/paste, we're going to set an environment variable for your account name. In the below command, replace `MY_ACCOUNT_NAME`:

    NEAR_ACCOUNT_NAME=MY_ACCOUNT_NAME

You can tell if the environment variable is set correctly if your command line prints the account name after this command:

    echo $NEAR_ACCOUNT_NAME

First, we'll deploy the compiled contract in this example to your account:

    near deploy --wasmFile res/fungible_token.wasm --accountId $NEAR_ACCOUNT_NAME

Since this example deals with a fungible token that can have an "escrow" owner, let's go ahead and set up two account names for Alice and Bob. These two accounts will be suffixes on your NEAR account name. This way it's unlikely that they're already reserved by someone else.

    near create_account $NEAR_ACCOUNT_NAME-alice --masterAccount $NEAR_ACCOUNT_NAME
    near create_account $NEAR_ACCOUNT_NAME-bob --masterAccount $NEAR_ACCOUNT_NAME

Create a token for an account and give it a total supply:

    near call $NEAR_ACCOUNT_NAME new '{"owner_id": "'$NEAR_ACCOUNT_NAME'", "total_supply": "1000000000000000"}' --accountId $NEAR_ACCOUNT_NAME

Get total supply:

    near view $NEAR_ACCOUNT_NAME get_total_supply --accountId $NEAR_ACCOUNT_NAME

Ensure the token balance on Bob's account:

    near view $NEAR_ACCOUNT_NAME get_balance '{"owner_id": "'$NEAR_ACCOUNT_NAME-bob'"}' --accountId $NEAR_ACCOUNT_NAME


Direct transfer
---------------

Transfer tokens **directly** to Bob from the contract that minted these fungible tokens:

    near call $NEAR_ACCOUNT_NAME transfer '{"new_owner_id": "'$NEAR_ACCOUNT_NAME-bob'", "amount": "19"}' --accountId $NEAR_ACCOUNT_NAME

Check the balance of Bob again with the command from before and it will now return `19`.


Transfer via escrow
-------------------

Here we will designate Alice as the account that has authority to send tokens on behalf of the main account, but up to a given limit.

Set escrow allowance for Alice:

    near call $NEAR_ACCOUNT_NAME set_allowance '{"escrow_account_id": "'$NEAR_ACCOUNT_NAME-alice'", "allowance": "1000000"}' --accountId $NEAR_ACCOUNT_NAME

Check escrow allowance:

    near view $NEAR_ACCOUNT_NAME get_allowance '{"owner_id": "'$NEAR_ACCOUNT_NAME'", "escrow_account_id": "'$NEAR_ACCOUNT_NAME-alice'"}' --accountId $NEAR_ACCOUNT_NAME

See that Alice actually has no tokens herself:

    near view $NEAR_ACCOUNT_NAME get_balance '{"owner_id": "'$NEAR_ACCOUNT_NAME-alice'"}' --accountId $NEAR_ACCOUNT_NAME

Transfer tokens from Alice to Bob through her allowance. Again, the tokens are coming from the main account that created the fungible tokens, not Alice's account, which has no tokens. Pay particular attention the end of this command, as we're telling `near-shell` to run this command with the credentials of alice using the `--accountId` flag.

    near call $NEAR_ACCOUNT_NAME transfer_from '{"owner_id": "'$NEAR_ACCOUNT_NAME'", "new_owner_id": "'$NEAR_ACCOUNT_NAME-bob'", "amount": "23"}' --accountId $NEAR_ACCOUNT_NAME-alice

Get the balance of Bob again:

    near view $NEAR_ACCOUNT_NAME get_balance '{"owner_id": "'$NEAR_ACCOUNT_NAME-bob'"}' --accountId $NEAR_ACCOUNT_NAME

This shows the result:

    42


Testing
=======

To test run:

    npm run test


Notes
=====

- The maximum balance value is limited by U128 (`2**128 - 1`).
- JSON calls should pass U128 as a base-10 string. E.g. `"100"`.
- The contract optimizes the inner trie structure by hashing account IDs. It will prevent some abuse of deep tries. This shouldn't be an issue once NEAR clients implement full hashing of keys.
- This contract doesn't optimize the amount of storage, since any account can create unlimited amount of allowances to other accounts. It's unclear how to address this issue unless this contract limits the total number of different allowances possible at the same time. And even if it limits the total number, it's still possible to transfer small amounts to multiple accounts.
