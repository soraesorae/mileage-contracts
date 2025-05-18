# mileage-contracts

SW Mileage contracts

## Requirements

-   [Foundry](https://github.com/foundry-rs/foundry)

## Build

### install dependencies

```shell
forge install
```

### build

```shell
forge build
```

### test

```shell
forge test
```

### build artifacts

```shell
./generate-build-artifacts.sh
ls artifacts/ | grep ".abi.json"
ls artifacts/ | grep ".bytecode.txt"
```

## Deploy contracts

### Setup

#### use anvil local testnet

```shell
anvil
```

#### use remote http json rpc

```shell
# .env file
DEPLOYER_PRIVATE_KEY=0x1234...
RPC_URL=http://127.0.0.1:8545
```

### Deploy

```shell
./deploy.sh
ls artifacts/ | grep "deploy.json"
```

Also, you can deploy with `forge script`, but it doesn't generate `artifacts/deploy.json`.

```shell
forge script script/SwMileageDeploy.s.sol --broadcast --skip-simulation --gas-estimate-multiplier 500
```

In our case, forge underestimates gas used of `deploy(...)` function in certain chain. Therefore, use temporarily `--gas-estimate-multiplier 500` to overestimate gas used.
