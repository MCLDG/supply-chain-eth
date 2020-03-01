#############################################################################################################
echo Create Kaleido ID registry service
#############################################################################################################
FARMER_REGISTRY_SERVICE=$(curl --request POST --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"name\": \"kaleido-registry-service\", \
    \"service\": \"idregistry\", \
    \"membership_id\": \"$FARMER_MEMBER_ID\" \
  }" \
  "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/services" | jq)

export FARMER_REGISTRY_SERVICE_ID=$(echo $FARMER_REGISTRY_SERVICE | jq -r "._id")
echo Provisioned Kaleido registry service with id: $FARMER_STORAGE_SERVICE_CONFIG_ID
echo Kaleido registry service response: $FARMER_REGISTRY_SERVICE
 