
#############################################################################################################
echo Deleting Kaleido consortium
#############################################################################################################
consortium=$(curl --request DELETE --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID" | jq)

echo Deleted Kaleido consortium with id: $CONSORTIUM_ID
echo Results of delete: $consortium
