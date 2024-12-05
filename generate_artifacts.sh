forge build --silent

jq '.bytecode.object' ./out/SwMileageToken.sol/SwMileageToken.json | sed -r 's/^.{3}//' | sed -r 's/.{1}$//' > bytecode.txt
jq '.bytecode.object' ./out/SwMileageFactory.sol/SwMileageTokenFactory.json | sed -r 's/^.{3}//' | sed -r 's/.{1}$//' > bytecode_factory.txt

jq '.abi' ./out/SwMileageToken.sol/SwMileageToken.json > abi.json
jq '.abi' ./out/SwMileageFactory.sol/SwMileageTokenFactory.json > abi_factory.json