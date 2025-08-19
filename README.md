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

#### using anvil local testnet

```shell
anvil
```

```shell
# .env file
DEPLOYER_PRIVATE_KEY=0x1234...
RPC_URL=http://127.0.0.1:8545
```

#### using remote http json rpc

```shell
# .env file
DEPLOYER_PRIVATE_KEY=0x1234...
RPC_URL=<REMOTE HTTP RPC URL>
```

### Deploy

```shell
./deploy-contracts.sh
ls artifacts/ | grep "deploy.json"
```

Also, you can deploy with `forge script`, but it doesn't generate `artifacts/deploy.json`.

```shell
forge script script/SwMileageDeploy.s.sol --broadcast --skip-simulation
```
