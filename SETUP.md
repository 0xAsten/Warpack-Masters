## Declare the external contracts

```
starkli declare --rpc https://api.cartridge.gg/x/starknet/sepolia --network sepolia --private-key 0x0... --account ~/.starknet_accounts/dojo_depolyment_account.json ./target/release/warpack_masters_MintableERC20Token.contract_class.json


Declaring Cairo 1 class: 0x0386d6cb28f2b72e772d6a4d0a8ed3264d588d4c4c35a0299832e23357e2a2c8
Compiling Sierra class to CASM with compiler version 2.11.4...
CASM class hash: 0x05f74410d61ea53cb467b95cba2c99aea31a859bfd31d690ae88a2f87bd6d1b5
Contract declaration transaction: 0x010227faaab6f3f70d0929265ed53e9d7558be9e9d863c7a6c67b8c17f1db3ba
Class hash declared:
0x0386d6cb28f2b72e772d6a4d0a8ed3264d588d4c4c35a0299832e23357e2a2c8
```

## Deploy the contratcs

```
starkli deploy --rpc https://api.cartridge.gg/x/starknet/sepolia --network sepolia --private-key 0x0... --account ~/.starknet_accounts/dojo_depolyment_account.json 0x0386d6cb28f2b72e772d6a4d0a8ed3264d588d4c4c35a0299832e23357e2a2c8 0x00 0x476f6c64 0x04 0x00 0x676f6c64 0x04 0x06cac844965c5d6517f3194ea13a884388fff54fae265a6d9e7ceec428a53a19 0x06cac844965c5d6517f3194ea13a884388fff54fae265a6d9e7ceec428a53a19 0x06cac844965c5d6517f3194ea13a884388fff54fae265a6d9e7ceec428a53a19

Deploying class 0x0386d6cb28f2b72e772d6a4d0a8ed3264d588d4c4c35a0299832e23357e2a2c8 with salt 0x04eb0fb2c50b6d516f7d562ac49b4da6b556ad7ab2558e23318cc1898604ad96...
The contract will be deployed at address 0x034dc20ea98d615518c783f498869d08d260dffec86fdef9448bd04ff8482001
Contract deployment transaction: 0x02e45f253ca0485f1e798dc678db9f24a328d8c97cc181d20596e657a958075a
Contract deployed:
0x034dc20ea98d615518c783f498869d08d260dffec86fdef9448bd04ff8482001
```

## Grant mint permisson to the Action System

https://sepolia.voyager.online/contract/0x034dc20ea98d615518c783f498869d08d260dffec86fdef9448bd04ff8482001#writeContract

Grant Minter Role: 0x032df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
to:
fight_system 0x41beab91983e25df3a91303ab8e2a302525042b0dc871639abafde8488a0b31
action 0x76347fb4152f015783c49f513ec5127c35833f3a699b496e3b02b31f9489704