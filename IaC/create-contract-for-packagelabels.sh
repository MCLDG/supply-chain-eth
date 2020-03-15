#############################################################################################################
echo Creating Kaleido CONTRACT
#############################################################################################################
PACKAGE_LABEL_CONTRACT=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"name\": \"packagel\", \
    \"description\": \"Contract for managing the labels affixed to packaging\", \
    \"membership_id\": \"$FARMER_MEMBER_ID\", \
    \"type\": \"github\" \
 }" "$APIURL/consortia/$CONSORTIUM_ID/contracts" | jq)

export PACKAGE_LABEL_CONTRACT_ID=$(echo $PACKAGE_LABEL_CONTRACT | jq -r "._id")
echo Created Kaleido contract for package label smart contract with id: $PACKAGE_LABEL_CONTRACT_ID
echo Contract $PACKAGE_LABEL_CONTRACT

#############################################################################################################
# This compiles the solidity code and stores it ready for promotion to specific environments. Compiling produces
# the bytecode, application binary interface (ABI), and developer docs. It also maintains
# a pointer back to the exact source code version (the commit)
#############################################################################################################
echo Creating Kaleido COMPILED CONTRACT
COMPILED_PACKAGE_LABEL_CONTRACT=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"description\": \"Compiled contract for managing the labels affixed to packaging\", \
    \"membership_id\": \"$FARMER_MEMBER_ID\", \
    \"contract_url\": \"https://github.com/MCLDG/supply-chain-eth/blob/master/contracts/PackageLabelsContract.sol\" \
 }" "$APIURL/consortia/$CONSORTIUM_ID/contracts/$PACKAGE_LABEL_CONTRACT_ID/compiled_contracts" | jq)

export COMPILED_PACKAGE_LABEL_CONTRACT_ID=$(echo $COMPILED_PACKAGE_LABEL_CONTRACT | jq -r "._id")
echo Created Kaleido compiled contract for package label smart contract with id: $COMPILED_PACKAGE_LABEL_CONTRACT_ID
echo Compiled Contract $COMPILED_PACKAGE_LABEL_CONTRACT

