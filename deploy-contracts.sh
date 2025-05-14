#!/bin/bash

SCRIPT_FILE_NAME="SwMileageDeploy.s.sol"
ARTIFACTS_DIR="./artifacts"
OUTPUT_FILE="$ARTIFACTS_DIR/deploy.json"

forge script script/$SCRIPT_FILE_NAME --broadcast --skip-simulation --gas-estimate-multiplier 500

mkdir -p $ARTIFACTS_DIR

CONTRACTS_JSON=$([ -f "$OUTPUT_FILE" ] && cat $OUTPUT_FILE || echo "{}")

# factory에서 배포한 proxy 컨트랙트 주소 파싱
# - deploy 함수 호출 트랜잭션 찾아서 해당 tx receipt log의 첫번째 주소 

for CHAIN_DIR in broadcast/$SCRIPT_FILE_NAME/*/; do
  [ -d "$CHAIN_DIR" ] || continue
  CHAIN_ID=$(basename "$CHAIN_DIR")
  LATEST_RUN=$CHAIN_DIR/run-latest.json
  
  if [ -n "$LATEST_RUN" ]; then
    echo "chain ID: $CHAIN_ID"
    
    TOKEN_FACTORY_INDEX=$(jq '.transactions | map(.contractName == "SwMileageTokenFactory" and .transactionType == "CREATE") | index(true)' $LATEST_RUN)
    MANAGER_FACTORY_INDEX=$(jq '.transactions | map(.contractName == "StudentManagerFactory" and .transactionType == "CREATE") | index(true)' $LATEST_RUN)
    TOKEN_IMPL_INDEX=$(jq '.transactions | map(.contractName == "SwMileageTokenImpl" and .transactionType == "CREATE") | index(true)' $LATEST_RUN)
    MANAGER_IMPL_INDEX=$(jq '.transactions | map(.contractName == "StudentManagerImpl" and .transactionType == "CREATE") | index(true)' $LATEST_RUN)
    
    TOKEN_DEPLOY_INDEX=$(jq '.transactions | map(.contractName == "SwMileageTokenFactory" and .function == "deploy(string,string)") | index(true)' $LATEST_RUN)
    MANAGER_DEPLOY_INDEX=$(jq '.transactions | map(.contractName == "StudentManagerFactory" and .function == "deploy(address)") | index(true)' $LATEST_RUN)
    
    TOKEN_FACTORY=$(jq -r ".transactions[$TOKEN_FACTORY_INDEX].contractAddress" $LATEST_RUN)
    MANAGER_FACTORY=$(jq -r ".transactions[$MANAGER_FACTORY_INDEX].contractAddress" $LATEST_RUN)
    TOKEN_IMPL=$(jq -r ".transactions[$TOKEN_IMPL_INDEX].contractAddress" $LATEST_RUN)
    MANAGER_IMPL=$(jq -r ".transactions[$MANAGER_IMPL_INDEX].contractAddress" $LATEST_RUN)
    
    TOKEN_PROXY=$(jq -r ".receipts[$TOKEN_DEPLOY_INDEX].logs[0].address" $LATEST_RUN)
    MANAGER_PROXY=$(jq -r ".receipts[$MANAGER_DEPLOY_INDEX].logs[0].address" $LATEST_RUN)
    
    echo "SwMileageTokenFactory: $TOKEN_FACTORY"
    echo "StudentManagerFactory: $MANAGER_FACTORY"
    echo "SwMileageTokenImpl (logic contract): $TOKEN_IMPL"
    echo "StudentManagerImpl: $MANAGER_IMPL"
    echo "SwMileageToken (proxy contract): $TOKEN_PROXY"
    echo "StudentManager (proxy contract): $MANAGER_PROXY"
    
    ALL_CONTRACTS=$(jq -n \
      --arg token_proxy "$TOKEN_PROXY" \
      --arg manager_proxy "$MANAGER_PROXY" \
      --arg token_factory "$TOKEN_FACTORY" \
      --arg manager_factory "$MANAGER_FACTORY" \
      --arg token_impl "$TOKEN_IMPL" \
      --arg manager_impl "$MANAGER_IMPL" \
      '{
        "SwMileageToken": $token_proxy,
        "StudentManager": $manager_proxy,
        "SwMileageTokenFactory": $token_factory,
        "StudentManagerFactory": $manager_factory,
        "SwMileageTokenImpl": $token_impl,
        "StudentManagerImpl": $manager_impl
      }')
    
    CONTRACTS_JSON=$(echo $CONTRACTS_JSON | \
      jq --arg chain "$CHAIN_ID" \
         --argjson contracts "$ALL_CONTRACTS" \
      '. + {($chain): {"contracts": $contracts}}')
  fi
done

echo $CONTRACTS_JSON | jq '.' > $OUTPUT_FILE
echo "output file path: $OUTPUT_FILE"