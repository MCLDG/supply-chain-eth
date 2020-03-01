#############################################################################################################
echo Provision Kaleido storage service - create the configuration
#############################################################################################################
FARMER_STORAGE_SERVICE_CONFIG=$(curl --request POST --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"name\": \"kaleido-storage-service-config\", \
    \"type\": \"storage\", \
    \"membership_id\": \"$FARMER_MEMBER_ID\", \
    \"details\":{\"provider\":\"aws\", \"region\":\"$REGION\", \"bucket\":\"$FARMER_STORAGE_BUCKET\", \"user_id\":\"$AWS_USER_ID\", \
    \"user_secret\":\"$AWS_USER_SECRET\"} \
  }" \
  "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/configurations" | jq)

export FARMER_STORAGE_SERVICE_CONFIG_ID=$(echo $FARMER_STORAGE_SERVICE_CONFIG | jq -r "._id")
echo Provisioned Kaleido storage service config with id: $FARMER_STORAGE_SERVICE_CONFIG_ID
echo Kaleido storage service config response: $FARMER_STORAGE_SERVICE_CONFIG
 
#############################################################################################################
echo Provision Kaleido storage service - create the service
#############################################################################################################
FARMER_STORAGE_SERVICE=$(curl --request POST --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"name\": \"kaleido-storage-service\", \
    \"service\": \"documentstore\", \
    \"membership_id\": \"$FARMER_MEMBER_ID\", \
    \"details\":{\"storage_id\":\"$FARMER_STORAGE_SERVICE_CONFIG_ID\"} \
  }" \
  "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/services" | jq)
  
export FARMER_STORAGE_SERVICE_ID=$(echo $FARMER_STORAGE_SERVICE | jq -r "._id")
echo Provisioned Kaleido storage service with id: $FARMER_STORAGE_SERVICE_ID
echo Kaleido storage service response: $FARMER_STORAGE_SERVICE
