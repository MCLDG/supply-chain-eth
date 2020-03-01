CONSORTIUM=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia?name=$CONSORTIUM_NAME" | jq)

export CONSORTIUM_NAME=$(echo $CONSORTIUM | jq -r ".[0].name")
export CONSORTIUM_ID=$(echo $CONSORTIUM | jq -r ".[0]._id")
export CONSORTIUM_OWNER=$(echo $CONSORTIUM | jq -r ".[0].owner")
export CONSORTIUM_REVISION=$(echo $CONSORTIUM | jq -r ".[0]._revision")
export CONSORTIUM_STATE=$(echo $CONSORTIUM | jq -r ".[0].state")
 
ENVIRONMENT=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments" | jq)

export ENVIRONMENT_NAME=$(echo $ENVIRONMENT | jq -r ".[0].name")
export ENVIRONMENT_ID=$(echo $ENVIRONMENT | jq -r ".[0]._id")
export ENVIRONMENT_PROVIDER=$(echo $ENVIRONMENT | jq -r ".[0].provider")
export ENVIRONMENT_CONSENSUS=$(echo $ENVIRONMENT | jq -r ".[0].consensus_type")
export ENVIRONMENT_REGION=$(echo $ENVIRONMENT | jq -r ".[0].region")

FARMER_MEMBER=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/memberships?org_name=Farmer" | jq)

export FARMER_MEMBER_ORG_NAME=$(echo $FARMER_MEMBER | jq -r ".[0].org_name")
export FARMER_MEMBER_ID=$(echo $FARMER_MEMBER | jq -r ".[0]._id")

COOP_MEMBER=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/memberships?org_name=Co-op" | jq)

export COOP_MEMBER_ORG_NAME=$(echo $COOP_MEMBER | jq -r ".[0].org_name")
export COOP_MEMBER_ID=$(echo $COOP_MEMBER | jq -r ".[0]._id")

SHIPPER_MEMBER=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/memberships?org_name=Shipper" | jq)

export SHIPPER_MEMBER_ORG_NAME=$(echo $SHIPPER_MEMBER | jq -r ".[0].org_name")
export SHIPPER_MEMBER_ID=$(echo $SHIPPER_MEMBER | jq -r ".[0]._id")

FARMER_NODE=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/nodes?name=FarmerNode" \
  | jq -r ".[0]")

export FARMER_NODE_NAME=$(echo $FARMER_NODE | jq -r ".name")
export FARMER_NODE_ID=$(echo $FARMER_NODE | jq -r "._id")
export FARMER_NODE_ROLE=$(echo $FARMER_NODE | jq -r ".role")
export FARMER_NODE_IDENTITY=$(echo $FARMER_NODE | jq -r ".node_identity")
export FARMER_NODE_CONSENSUS_IDENTITY=$(echo $FARMER_NODE | jq -r ".consensus_identity")
export FARMER_NODE_URL_RPC=$(echo $FARMER_NODE | jq -r ".urls.rpc")
export FARMER_NODE_URL_WSS=$(echo $FARMER_NODE | jq -r ".urls.wss")
export FARMER_NODE_URL_KALEIDO_CONNECT=$(echo $FARMER_NODE | jq -r ".urls.kaleido_connect")
export FARMER_NODE_URL_PRIVATE_TX=$(echo $FARMER_NODE | jq -r ".urls.private_tx")

FARMER_NODE=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/nodes/$FARMER_NODE_ID/status" \
  | jq)

export FARMER_NODE_PRIVATE_ADDRESS=$(echo $FARMER_NODE | jq -r ".quorum.private_address")
export FARMER_NODE_PUBLIC_ADDRESS=$(echo $FARMER_NODE | jq -r ".quorum.public_address")
export FARMER_NODE_KAFKA_BROKERS=$(echo $FARMER_NODE | jq -r ".kafka.brokers")
export FARMER_NODE_KAFKA_REQUEST_TOPIC=$(echo $FARMER_NODE | jq -r ".kafka.request_topic")
export FARMER_NODE_KAFKA_REPLY_TOPIC=$(echo $FARMER_NODE | jq -r ".kafka.reply_topic")

COOP_NODE=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/nodes?name=CoopNode" \
  | jq -r ".[0]")

export COOP_NODE_NAME=$(echo $COOP_NODE | jq -r ".name")
export COOP_NODE_ID=$(echo $COOP_NODE | jq -r "._id")
export COOP_NODE_ROLE=$(echo $COOP_NODE | jq -r ".role")
export COOP_NODE_IDENTITY=$(echo $COOP_NODE | jq -r ".node_identity")
export COOP_NODE_CONSENSUS_IDENTITY=$(echo $COOP_NODE | jq -r ".consensus_identity")
export COOP_NODE_URL_RPC=$(echo $COOP_NODE | jq -r ".urls.rpc")
export COOP_NODE_URL_WSS=$(echo $COOP_NODE | jq -r ".urls.wss")
export COOP_NODE_URL_KALEIDO_CONNECT=$(echo $COOP_NODE | jq -r ".urls.kaleido_connect")
export COOP_NODE_URL_PRIVATE_TX=$(echo $COOP_NODE | jq -r ".urls.private_tx")

COOP_NODE=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/nodes/$COOP_NODE_ID/status" \
  | jq)

export COOP_NODE_PRIVATE_ADDRESS=$(echo $COOP_NODE | jq -r ".quorum.private_address")
export COOP_NODE_PUBLIC_ADDRESS=$(echo $COOP_NODE | jq -r ".quorum.public_address")
export COOP_NODE_KAFKA_BROKERS=$(echo $COOP_NODE | jq -r ".kafka.brokers")
export COOP_NODE_KAFKA_REQUEST_TOPIC=$(echo $COOP_NODE | jq -r ".kafka.request_topic")
export COOP_NODE_KAFKA_REPLY_TOPIC=$(echo $COOP_NODE | jq -r ".kafka.reply_topic")

SHIPPER_NODE=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/nodes?name=ShipperNode" \
  | jq -r ".[0]")

export SHIPPER_NODE_NAME=$(echo $SHIPPER_NODE | jq -r ".name")
export SHIPPER_NODE_ID=$(echo $SHIPPER_NODE | jq -r "._id")
export SHIPPER_NODE_ROLE=$(echo $SHIPPER_NODE | jq -r ".role")
export SHIPPER_NODE_IDENTITY=$(echo $SHIPPER_NODE | jq -r ".node_identity")
export SHIPPER_NODE_CONSENSUS_IDENTITY=$(echo $SHIPPER_NODE | jq -r ".consensus_identity")
export SHIPPER_NODE_URL_RPC=$(echo $SHIPPER_NODE | jq -r ".urls.rpc")
export SHIPPER_NODE_URL_WSS=$(echo $SHIPPER_NODE | jq -r ".urls.wss")
export SHIPPER_NODE_URL_KALEIDO_CONNECT=$(echo $SHIPPER_NODE | jq -r ".urls.kaleido_connect")
export SHIPPER_NODE_URL_PRIVATE_TX=$(echo $SHIPPER_NODE | jq -r ".urls.private_tx")

SHIPPER_NODE=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/nodes/$SHIPPER_NODE_ID/status" \
  | jq)

export SHIPPER_NODE_PRIVATE_ADDRESS=$(echo $SHIPPER_NODE | jq -r ".quorum.private_address")
export SHIPPER_NODE_PUBLIC_ADDRESS=$(echo $SHIPPER_NODE | jq -r ".quorum.public_address")
export SHIPPER_NODE_KAFKA_BROKERS=$(echo $SHIPPER_NODE | jq -r ".kafka.brokers")
export SHIPPER_NODE_KAFKA_REQUEST_TOPIC=$(echo $SHIPPER_NODE | jq -r ".kafka.request_topic")
export SHIPPER_NODE_KAFKA_REPLY_TOPIC=$(echo $SHIPPER_NODE | jq -r ".kafka.reply_topic")

#############################################################################################################
# Get the Kaleido IPFS service details
#############################################################################################################
IPFS_NODE=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/services?service=ipfs" | jq)

export IPFS_NODE_ID=$(echo $IPFS_NODE | jq -r ".[0]._id")
export IPFS_NODE_NAME=$(echo $IPFS_NODE | jq -r ".[0].name")
export IPFS_NODE_PEER_ID=$(echo $IPFS_NODE | jq -r ".[0].details.ipfs_peer_id")
export IPFS_NODE_URL_HTTP=$(echo $IPFS_NODE | jq -r ".[0].urls.http")
export IPFS_NODE_URL_WSS=$(echo $IPFS_NODE | jq -r ".[0].urls.ws")
export IPFS_NODE_URL_WEBUI=$(echo $IPFS_NODE | jq -r ".[0].urls.webui")

#############################################################################################################
# Get the Kaleido Document storage service details
#############################################################################################################

DOCUMENT_STORAGE=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/services?name=kaleido-storage-service" | jq)

export DOCUMENT_STORAGE_ID=$(echo $DOCUMENT_STORAGE | jq -r ".[0]._id")
export DOCUMENT_STORAGE_NAME=$(echo $DOCUMENT_STORAGE | jq -r ".[0].name")
export DOCUMENT_STORAGE_STORAGE_ID=$(echo $DOCUMENT_STORAGE | jq -r ".[0].details.storage_id")
export DOCUMENT_STORAGE_URL_HTTP=$(echo $DOCUMENT_STORAGE | jq -r ".[0].urls.http")
export DOCUMENT_STORAGE_URL_WSS=$(echo $DOCUMENT_STORAGE | jq -r ".[0].urls.ws")

#############################################################################################################
# Get the Kaleido ID registry service details
#############################################################################################################

REGISTRY_SERVICE=$(curl --header "$HDR_AUTH" --header "$HDR_CT" --silent "$APIURL/consortia/$CONSORTIUM_ID/environments/$ENVIRONMENT_ID/services?name=kaleido-registry-service" | jq)

export REGISTRY_SERVICE_ID=$(echo $REGISTRY_SERVICE | jq -r ".[0]._id")
export REGISTRY_SERVICE_NAME=$(echo $REGISTRY_SERVICE | jq -r ".[0].name")
export REGISTRY_SERVICE_STORAGE_ID=$(echo $REGISTRY_SERVICE | jq -r ".[0].details.storage_id")
export REGISTRY_SERVICE_URL_HTTP=$(echo $REGISTRY_SERVICE | jq -r ".[0].urls.http")
export REGISTRY_SERVICE_URL_WSS=$(echo $REGISTRY_SERVICE | jq -r ".[0].urls.ws")

echo Consortium variables
echo =====================
env | grep CONSORTIUM

echo Environment variables
echo =====================
env | grep ENVIRONMENT

echo FARMER variables
echo =====================
env | grep FARMER_MEMBER
env | grep FARMER_NODE

echo COOP variables
echo =====================
env | grep COOP_MEMBER
env | grep COOP_NODE

echo SHIPPER variables
echo =====================
env | grep SHIPPER_MEMBER
env | grep SHIPPER_NODE

echo IPFS variables
echo =====================
env | grep IPFS_NODE

echo Document Storage variables
echo ==========================
env | grep DOCUMENT_STORAGE

echo Registry service variables
echo ==========================
env | grep REGISTRY_SERVICE
