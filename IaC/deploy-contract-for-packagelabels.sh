#############################################################################################################
echo Deployed Kaleido COMPILED CONTRACT to environment 
#############################################################################################################
DEPLOYED_PACKAGE_LABEL_CONTRACT=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"environment_id\": \"$ENVIRONMENT_ID\", \
    \"endpoint\": \"packagelabels\" \
  }" "$APIURL/consortia/$CONSORTIUM_ID/contracts/$PACKAGE_LABEL_CONTRACT_ID/compiled_contracts/$COMPILED_PACKAGE_LABEL_CONTRACT_ID/promote" | jq)

export DEPLOYED_PACKAGE_LABEL_CONTRACT_ID=$(echo $DEPLOYED_PACKAGE_LABEL_CONTRACT | jq -r "._id")
echo Deploy Kaleido compiled contract for package label smart contract with id: $COMPILED_PACKAGE_LABEL_CONTRACT_ID to environment $ENVIRONMENT_ID
echo Deployed Contract $DEPLOYED_PACKAGE_LABEL_CONTRACT

