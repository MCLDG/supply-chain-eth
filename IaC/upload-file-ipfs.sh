#############################################################################################################
echo Uploading file to IPFS
#############################################################################################################
IPFS_UPLOAD=$(curl --silent --form "path=@$FILE_PATH_TO_UPLOAD" \
  https://$FARMER_CREDS_USERNAME:$FARMER_CREDS_PASSWORD@${IPFS_NODE_URL_HTTP:8}/api/v0/add)

IPFS_UPLOAD_HASH=$(echo $IPFS_UPLOAD | jq -r ".Hash")
echo Uploaded file to IPFS. Hash: $IPFS_UPLOAD_HASH
echo IPFS upload response: $IPFS_UPLOAD