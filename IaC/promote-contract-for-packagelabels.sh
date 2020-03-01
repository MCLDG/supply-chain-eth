#############################################################################################################
# This stores the smart contract in the Kaleido registry along with the bytecode, application binary 
# interface (ABI), and developer docs. Once it is stored in the registry, a REST API is generated and 
# available to all nodes. It can be used to interact with the smart contract.
# The smart contract is not instantiated during promotion.
#############################################################################################################
echo Promoting Kaleido COMPILED CONTRACT to environment 
PROMOTE_PACKAGE_LABEL_CONTRACT=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"environment_id\": \"$ENVIRONMENT_ID\", \
    \"endpoint\": \"packagel\" \
  }" "$APIURL/consortia/$CONSORTIUM_ID/contracts/$PACKAGE_LABEL_CONTRACT_ID/compiled_contracts/$COMPILED_PACKAGE_LABEL_CONTRACT_ID/promote" | jq)

export PROMOTE_PACKAGE_LABEL_CONTRACT_ID=$(echo $PROMOTE_PACKAGE_LABEL_CONTRACT | jq -r "._id")
echo Promoted Kaleido compiled contract for package label smart contract with id: $COMPILED_PACKAGE_LABEL_CONTRACT_ID to environment $ENVIRONMENT_ID
echo Promoted Contract $DEPLOYED_PACKAGE_LABEL_CONTRACT

