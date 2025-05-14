# mileage-contracts

-   Foundry

## Usage

-   install foundry
-   install dependencies
    ```bash
    $ forge install
    ```
-   forge build, test
    ```bash
    $ forge build
    $ forge test
    ```
-   deploy contracts
    -   using anvil local testnet
    ```bash
    $ anvil
    ```
    -   or using remote rpc
    ```
    # .env file
    DEPLOYER_PRIVATE_KEY=0x1234...
    RPC_URL=http://127.0.0.1:8545
    ```
    -   generate artifacts
    ```bash
    $ ./deploy.sh
    $ ./generate artifacts
    ```
    -   artifacts saved to artifacts/
