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
# Other info
#############################################################################################################


curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/zones" | jq
