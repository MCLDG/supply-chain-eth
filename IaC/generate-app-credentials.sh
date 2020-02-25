echo Creating application credentials for member: $MEMBER_ID

CREDS=$(curl --header "$HDR_AUTH" --header "$HDR_CT" \
  --request POST --silent --data "{\"membership_id\":\"$MEMBER_ID\"}" \
  "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/appcreds" \
  | jq)

echo $CREDS | jq

export CREDS_USERNAME=$(echo $CREDS | jq -r ".username")
export CREDS_PASSWORD=$(echo $CREDS | jq -r ".password")