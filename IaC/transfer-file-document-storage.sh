#############################################################################################################
echo Uploading file to Document Storage
#############################################################################################################
DOCUMENT_UPLOAD=$(curl --silent --data "{ \
    \"from\": \"$SHIPPER_DEST\", \
    \"to\": \"$FARMER_DEST\", \
    \"document\": \"$FILE_NAME\" \
  }" \
  https://$FARMER_CREDS_USERNAME:$FARMER_CREDS_PASSWORD@${DOCUMENT_STORAGE_URL_HTTP:8}/api/v1/transfers)

DOCUMENT_UPLOAD_HASH=$(echo $DOCUMENT_UPLOAD | jq -r ".hash")
echo Uploaded file to Document Storage. Hash: $DOCUMENT_UPLOAD_HASH
echo Document upload response: $DOCUMENT_UPLOAD


kld://documentstore/m/u0yjymivae/e/u0x83bqeuj/s/u0v9kzyj82/d/shipper-dest to kld://documentstore/m/u0yjymivae/e/u0x83bqeuj/s/u0v9kzyj82/d/farmer-dest

u0x83bqeuj-u0v9kzyj82-documentstore-farmer-dest
u0x83bqeuj-u0v9kzyj82-documentstore-shipper-dest