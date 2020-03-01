#############################################################################################################
echo Uploading file to Document Storage
#############################################################################################################
DOCUMENT_UPLOAD=$(curl --silent --form "document=@$FILE_PATH_TO_UPLOAD" \
  https://$FARMER_CREDS_USERNAME:$FARMER_CREDS_PASSWORD@${DOCUMENT_STORAGE_URL_HTTP:8}/api/v1/documents/$FILE_NAME)

DOCUMENT_UPLOAD_HASH=$(echo $DOCUMENT_UPLOAD | jq -r ".hash")
echo Uploaded file to Document Storage. Hash: $DOCUMENT_UPLOAD_HASH
echo Document upload response: $DOCUMENT_UPLOAD