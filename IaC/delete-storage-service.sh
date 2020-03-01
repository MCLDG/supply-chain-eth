#############################################################################################################
echo Delete Kaleido storage service - delete the service
#############################################################################################################
FARMER_STORAGE_SERVICE=$(curl --request DELETE --header "$HDR_AUTH" --header "$HDR_CT" --silent \
  "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/services/$FARMER_STORAGE_SERVICE_ID" | jq)
  
echo Delete Kaleido storage service response: $FARMER_STORAGE_SERVICE

#############################################################################################################
echo Delete Kaleido storage service - delete the configuration
#############################################################################################################
FARMER_STORAGE_SERVICE_CONFIG=$(curl --request POST --header "$HDR_AUTH" --header "$HDR_CT" --silent \
  "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/configurations/$FARMER_STORAGE_SERVICE_CONFIG_ID" | jq)

echo Delete Kaleido storage service config response: $FARMER_STORAGE_SERVICE_CONFIG
