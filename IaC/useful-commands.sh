#############################################################################################################
# Get blocks & transactions
#############################################################################################################

curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/ledger/$CONSORTIUM_ID/$ENVIRONMENT_ID/blocks?limit=10" | jq

curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/ledger/$CONSORTIUM_ID/$ENVIRONMENT_ID/blocks/17283" | jq

curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/ledger/$CONSORTIUM_ID/$ENVIRONMENT_ID/blocks/17283/transactions" | jq

curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/ledger/$CONSORTIUM_ID/$ENVIRONMENT_ID/transactions/0xecfd17930703a213d21ad35b79df305b3b73fd4b911476332d93d689e81ea781" | jq

curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/ledger/$CONSORTIUM_ID/$ENVIRONMENT_ID/transactions/0xecfd17930703a213d21ad35b79df305b3b73fd4b911476332d93d689e81ea781/receipt" | jq

#############################################################################################################
# Get contract info
#############################################################################################################

curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/ledger/$CONSORTIUM_ID/$ENVIRONMENT_ID/addresses/0x969dafa086396e08c030698d206499fc62210c02" | jq

curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/ledger/$CONSORTIUM_ID/$ENVIRONMENT_ID/addresses/0x969dafa086396e08c030698d206499fc62210c02/transactions" | jq

curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/ledger/$CONSORTIUM_ID/$ENVIRONMENT_ID/contracts" | jq

curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/ledger/$CONSORTIUM_ID/$ENVIRONMENT_ID/contracts/0x969dafa086396e08c030698d206499fc62210c02" | jq

#############################################################################################################
# Tokens
#############################################################################################################

curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/contracts" | jq

#############################################################################################################
# Other info
#############################################################################################################

curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/zones" | jq

curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/configurations" | jq

curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/services" | jq

curl --request DELETE --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/services/service_id" | jq

export FARMER_CREDS_USERNAME=$CREDS_USERNAME
export FARMER_CREDS_PASSWORD=$CREDS_PASSWORD
export FARMER_FULL_URL=https://${FARMER_CREDS_USERNAME}:${FARMER_CREDS_PASSWORD}@${FARMER_NODE_URL_RPC:8}
curl --verbose $FARMER_FULL_URL/api/v0/config

HASH=cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30
FILENAME=LICENSE
curl --silent https://$FARMER_CREDS_USERNAME:$FARMER_CREDS_PASSWORD@${DOCUMENT_STORAGE_URL_HTTP:8}/api/v1/config
curl --silent https://$FARMER_CREDS_USERNAME:$FARMER_CREDS_PASSWORD@${DOCUMENT_STORAGE_URL_HTTP:8}/api/v1/search?query=$FILE_NAME
curl --silent https://$FARMER_CREDS_USERNAME:$FARMER_CREDS_PASSWORD@${DOCUMENT_STORAGE_URL_HTTP:8}/api/v1/search?query=$HASH,by_hash=true
curl --silent https://$FARMER_CREDS_USERNAME:$FARMER_CREDS_PASSWORD@${DOCUMENT_STORAGE_URL_HTTP:8}/api/v1/documents
