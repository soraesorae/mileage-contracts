#!/bin/bash

forge build --silent

jq '.bytecode.object' ./out/SwMileageToken.impl.sol/SwMileageTokenImpl.json | sed -r 's/^.{3}//' | sed -r 's/.{1}$//' > ./artifacts/SwMileageToken.bytecode.txt
jq '.bytecode.object' ./out/StudentManager.impl.sol/StudentManagerImpl.json | sed -r 's/^.{3}//' | sed -r 's/.{1}$//' > ./artifacts/StudentManager.bytecode.txt

jq '.abi' ./out/SwMileageToken.impl.sol/SwMileageTokenImpl.json > ./artifacts/SwMileageToken.abi.json
jq '.abi' ./out/StudentManager.impl.sol/StudentManagerImpl.json > ./artifacts/StudentManager.abi.json