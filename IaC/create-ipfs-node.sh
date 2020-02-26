#############################################################################################################
echo Provision Kaleido IPFS service
#############################################################################################################
IPFS=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent --data "{ \
    \"name\": \"supply-chain-ipfs-node\", \
    \"service\": \"ipfs\", \
    \"membership_id\": \"$FARMER_MEMBER_ID\" \
  }" \
  "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/services" | jq)

export IPFS_ID=$(echo $IPFS | jq -r "._id")
echo Provisioned Kaleido IPFS service with id: $IPFS_ID
echo IPFS response: $IPFS
 
#############################################################################################################
echo Creating Kaleido IPFS node
#############################################################################################################
IPFS_NODE=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/services/$IPFS_ID" | jq)

export IPFS_NODE_ID=$(echo $IPFS_NODE | jq -r "._id")
echo Provisioned Kaleido IPFS node with id: $IPFS_NODE_ID
echo IPFS response: $IPFS_NODE

