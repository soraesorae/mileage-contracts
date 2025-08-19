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
    
    TOKEN_IMPL_INDEX=$(jq '.transactions | map(.contractName == "SwMileageTokenImpl" and .transactionType == "CREATE") | indices(true)[0]' $LATEST_RUN)
    TOKEN_DEPLOY_INDEX=$(jq '.transactions | map(.contractName == "SwMileageTokenImpl" and .transactionType == "CREATE") | indices(true)[1]' $LATEST_RUN)
    STUDENT_MANAGER_INDEX=$(jq '.transactions | map(.contractName == "StudentManagerImpl" and .transactionType == "CREATE") | index(true)' $LATEST_RUN)
    
    TOKEN_IMPL=$(jq -r ".transactions[$TOKEN_IMPL_INDEX].contractAddress" $LATEST_RUN)
    TOKEN_DEPLOY=$(jq -r ".receipts[$TOKEN_DEPLOY_INDEX].contractAddress" $LATEST_RUN)
    STUDENT_MANAGER_DEPLOY=$(jq -r ".transactions[$STUDENT_MANAGER_INDEX].contractAddress" $LATEST_RUN)
    
    echo "SwMileageTokenImpl (logic contract): $TOKEN_IMPL"
    echo "SwMileageToken: $TOKEN_DEPLOY"
    echo "StudentManager: $STUDENT_MANAGER_DEPLOY"
    
    ALL_CONTRACTS=$(jq -n \
      --arg token_impl "$TOKEN_IMPL" \
      --arg token_deploy "$TOKEN_DEPLOY" \
      --arg manager_deploy "$STUDENT_MANAGER_DEPLOY" \
      '{
        "SwMileageTokenImpl": $token_impl,
        "SwMileageToken": $token_deploy,
        "StudentManager": $manager_deploy,
      }')
    
    CONTRACTS_JSON=$(echo $CONTRACTS_JSON | \
      jq --arg chain "$CHAIN_ID" \
         --argjson contracts "$ALL_CONTRACTS" \
      '. + {($chain): {"contracts": $contracts}}')
  fi
done

echo $CONTRACTS_JSON | jq '.' > $OUTPUT_FILE
echo "output file path: $OUTPUT_FILE"