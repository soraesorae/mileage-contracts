#!/bin/bash

ARTIFACTS_DIR="./artifacts"

forge build --silent

mkdir -p $ARTIFACTS_DIR

jq '.bytecode.object' ./out/SwMileageToken.impl.sol/SwMileageTokenImpl.json | sed -r 's/^.{3}//' | sed -r 's/.{1}$//' > ./artifacts/SwMileageToken.bytecode.txt
jq '.bytecode.object' ./out/StudentManager.impl.sol/StudentManagerImpl.json | sed -r 's/^.{3}//' | sed -r 's/.{1}$//' > ./artifacts/StudentManager.bytecode.txt
jq '.bytecode.object' ./out/SwMileageFactory.sol/SwMileageTokenFactory.json  | sed -r 's/^.{3}//' | sed -r 's/.{1}$//' > ./artifacts/SwMileageTokenFactory.bytecode.txt
jq '.bytecode.object' ./out/StudentManagerFactory.sol/StudentManagerFactory.json | sed -r 's/^.{3}//' | sed -r 's/.{1}$//' > ./artifacts/StudentManagerFactory.bytecode.txt

jq '.abi' ./out/SwMileageToken.impl.sol/SwMileageTokenImpl.json > ./artifacts/SwMileageToken.abi.json
jq '.abi' ./out/StudentManager.impl.sol/StudentManagerImpl.json > ./artifacts/StudentManager.abi.json
jq '.abi' ./out/SwMileageFactory.sol/SwMileageTokenFactory.json > ./artifacts/SwMileageTokenFactory.abi.json
jq '.abi' ./out/StudentManagerFactory.sol/StudentManagerFactory.json > ./artifacts/StudentManagerFactory.abi.json