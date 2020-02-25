#############################################################################################################
echo Delete Kaleido COMPILED CONTRACT
#############################################################################################################
COMPILED_PACKAGE_LABEL_CONTRACT=$(curl --request DELETE --header "$HDR_AUTH" --header "$HDR_CT" --silent \
    "$APIURL/consortia/$CONSORTIUM_ID/contracts/$PACKAGE_LABEL_CONTRACT_ID/compiled_contracts/$COMPILED_PACKAGE_LABEL_CONTRACT_ID" | jq)

echo Deleted Kaleido compiled contract for package label smart contract with id: $COMPILED_PACKAGE_LABEL_CONTRACT_ID
echo Result of delete $COMPILED_PACKAGE_LABEL_CONTRACT

#############################################################################################################
echo Creating Kaleido CONTRACT
#############################################################################################################
PACKAGE_LABEL_CONTRACT=$(curl --request DELETE --header "$HDR_AUTH" --header "$HDR_CT" --silent \
    "$APIURL/consortia/$CONSORTIUM_ID/contracts/$PACKAGE_LABEL_CONTRACT_ID" | jq)

echo Deleted Kaleido contract for package label smart contract with id: $PACKAGE_LABEL_CONTRACT_ID
echo Result of delete $PACKAGE_LABEL_CONTRACT
