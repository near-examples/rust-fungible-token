# Fungible token

Example implementation of a Fungible Token Standard (NEP#21).

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/near-examples/rust-fungible-token)

## Prerequisite
Ensure `near-shell` is installed by running:

```
near --version
```

If needed, install `near-shell`:

```
npm install near-shell -g
```

## Building this contract
There are a number of special flags used to compile the smart contract into the wasm file.
Run this command to build and place the wasm file in the `res` directory:
```bash
./build.sh
```

## Using this contract

This smart contract will get deployed to your NEAR account. If you do not have a NEAR account, please create one with [NEAR Wallet](https://wallet.nearprotocol.com).

In the project root, login with `near-shell` by following the instructions after this command:

```bash
near login
```

To make this tutorial easier to copy/paste, we're going to set an environment variable for your account name. In the below command, replace `MY_ACCOUNT_NAME`:

```bash
NEAR_ACCOUNT_NAME=MY_ACCOUNT_NAME
```

You can tell if the environment variable is set correctly if your command line prints the account name after this command:
```bash
echo $NEAR_ACCOUNT_NAME
```

First, we'll deploy the compiled contract in this example to your account:

```bash
near deploy --wasmFile res/fungible_token.wasm --accountId $NEAR_ACCOUNT_NAME
```

Since this example deals with a fungible token that can have an "escrow" owner, let's go ahead and set up two account names for Alice and Bob.
These two accounts will be suffixes on your NEAR account name. This way it's unlikely that they're already reserved by someone else.
```bash
near create_account $NEAR_ACCOUNT_NAME-alice --masterAccount $NEAR_ACCOUNT_NAME
near create_account $NEAR_ACCOUNT_NAME-bob --masterAccount $NEAR_ACCOUNT_NAME
```

Create a token for an account and give it a total supply:
```bash
near call $NEAR_ACCOUNT_NAME new '{"owner_id": "'$NEAR_ACCOUNT_NAME'", "total_supply": "1000000000000000"}' --accountId $NEAR_ACCOUNT_NAME
```

Get total supply:
```bash
near view $NEAR_ACCOUNT_NAME get_total_supply --accountId $NEAR_ACCOUNT_NAME
```

Ensure the token balance on Bob's account:
```bash
near view $NEAR_ACCOUNT_NAME get_balance '{"owner_id": "'$NEAR_ACCOUNT_NAME-bob'"}' --accountId $NEAR_ACCOUNT_NAME
```

### Direct transfer

Transfer tokens **directly** to Bob from the contract that minted these fungible tokens:
```bash
near call $NEAR_ACCOUNT_NAME transfer '{"new_owner_id": "'$NEAR_ACCOUNT_NAME-bob'", "amount": "19"}' --accountId $NEAR_ACCOUNT_NAME
```

Check the balance of Bob again with the command from before and it will now return `19`.

### Transfer via escrow

Here we will designate Alice as the account that has authority to send tokens on behalf of the main account, but up to a given limit.

Set escrow allowance for Alice:
```bash
near call $NEAR_ACCOUNT_NAME set_allowance '{"escrow_account_id": "'$NEAR_ACCOUNT_NAME-alice'", "allowance": "1000000"}' --accountId $NEAR_ACCOUNT_NAME
```

Check escrow allowance:
```bash
near view $NEAR_ACCOUNT_NAME get_allowance '{"owner_id": "'$NEAR_ACCOUNT_NAME'", "escrow_account_id": "'$NEAR_ACCOUNT_NAME-alice'"}' --accountId $NEAR_ACCOUNT_NAME
```

See that Alice actually has no tokens herself:
```bash
near view $NEAR_ACCOUNT_NAME get_balance '{"owner_id": "'$NEAR_ACCOUNT_NAME-alice'"}' --accountId $NEAR_ACCOUNT_NAME
```

Transfer tokens from Alice to Bob through her allowance. Again, the tokens are coming from the main account that created the fungible tokens, not Alice's account, which has no tokens. Pay particular attention the end of this command, as we're telling `near-shell` to run this command with the credentials of alice using the `--accountId` flag.
```bash
near call $NEAR_ACCOUNT_NAME transfer_from '{"owner_id": "'$NEAR_ACCOUNT_NAME'", "new_owner_id": "'$NEAR_ACCOUNT_NAME-bob'", "amount": "'23'"}' --accountId $NEAR_ACCOUNT_NAME-alice
```

Get the balance of Bob again:
`near view $NEAR_ACCOUNT_NAME get_balance '{"owner_id": "'$NEAR_ACCOUNT_NAME-bob'"}' --accountId $NEAR_ACCOUNT_NAME`

This shows the result:
```bash
42
```

## Testing
To test run:
```bash
cargo test --package fungible-token -- --nocapture
```

## Notes
 - The maximum balance value is limited by U128 (2**128 - 1).
 - JSON calls should pass U128 as a base-10 string. E.g. "100".
 - The contract optimizes the inner trie structure by hashing account IDs. It will prevent some
    abuse of deep tries. Shouldn't be an issue, once NEAR clients implement full hashing of keys.
  - This contract doesn't optimize the amount of storage, since any account can create unlimited
    amount of allowances to other accounts. It's unclear how to address this issue unless, this
    contract limits the total number of different allowances possible at the same time.
    And even if it limits the total number, it's still possible to transfer small amounts to
    multiple accounts.