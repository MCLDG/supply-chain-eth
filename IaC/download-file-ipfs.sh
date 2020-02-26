#############################################################################################################
echo Downloading file from IPFS
#############################################################################################################
IPFS_DOWNLOAD=$(curl --silent --output $FILE_PATH_TO_DOWNLOAD \
  https://$FARMER_CREDS_USERNAME:$FARMER_CREDS_PASSWORD@${IPFS_NODE_URL_HTTP:8}/api/v0/cat/$IPFS_DOWNLOAD_HASH)

echo IPFS download response: $IPFS_DOWNLOAD
ls -l $FILE_PATH_TO_DOWNLOAD
