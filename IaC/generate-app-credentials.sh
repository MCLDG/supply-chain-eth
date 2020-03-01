echo Creating application credentials for member: $MEMBER_ID

CREDS=$(curl --request POST --header "$HDR_AUTH" --header "$HDR_CT" --silent \
  --data "{\"membership_id\":\"$MEMBER_ID\", \
  \"name\": \"$MEMBER_ID-app-creds\"
  }" \
  "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/appcreds" \
  | jq)

echo $CREDS | jq

export CREDS_USERNAME=$(echo $CREDS | jq -r ".username")
export CREDS_PASSWORD=$(echo $CREDS | jq -r ".password")